import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_document.dart';
import '../models/establishment.dart';
import '../models/fueling_record.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../models/vehicle_expense.dart';
import 'access_service.dart';
import 'document_storage_service.dart';
import 'establishment_storage_service.dart';
import 'expense_storage_service.dart';
import 'fueling_storage_service.dart';
import 'maintenance_storage_service.dart';
import 'vehicle_storage_service.dart';
import '../l10n/l10n.dart';

/// Backup automático em nuvem do Premium.
///
/// Cada registro (veículo, abastecimento, manutenção, despesa, local e
/// documento) vira um documento em `users/{uid}/backupItems` no Firestore,
/// com o JSON do registro. Fotos, comprovantes e PDFs vão para o Storage em
/// `users/{uid}/files/...`; no JSON salvo na nuvem o caminho local do arquivo
/// é trocado por `cloud:<chave>`, uma chave derivada do registro (e não do
/// aparelho), para que o mesmo arquivo tenha o mesmo nome em qualquer celular.
///
/// Os armazenamentos locais chamam [markDirty] a cada gravação; o envio
/// acontece alguns segundos depois, ao sair do app ou ao abrir o app. Só o
/// que mudou desde o último envio é enviado (ver [_BackupState]).
///
/// Quem decide se o usuário pode gravar na nuvem são as regras do servidor
/// (`firestore.rules` e `storage.rules`); o app só evita tentar quando já
/// sabe que o usuário não é assinante.
class AutoBackupService extends ChangeNotifier with WidgetsBindingObserver {
  AutoBackupService._();
  static final AutoBackupService instance = AutoBackupService._();

  static const _debounce = Duration(seconds: 8);
  static const _cloudPrefix = 'cloud:';
  static const _batchLimit = 400;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _vehicles = VehicleStorageService();
  final _fuelings = FuelingStorageService();
  final _maintenances = MaintenanceStorageService();
  final _expenses = ExpenseStorageService();
  final _establishments = EstablishmentStorageService();
  final _documents = DocumentStorageService();

  Timer? _timer;
  bool _started = false;
  bool _restoring = false;
  bool _dirty = false;
  Future<void>? _running;
  bool _wasEnabled = false;

  bool get running => _running != null;
  DateTime? lastBackupAt;
  String? lastError;

  bool get _enabled =>
      _auth.currentUser != null && AccessService.instance.cloudBackupEnabled;

  /// Começa a acompanhar a assinatura e o ciclo de vida do app. Chamado uma
  /// vez, depois de [AccessService.initialize].
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    AccessService.instance.addListener(_onAccessChanged);
    unawaited(_loadLastBackupAt());
    _onAccessChanged();
  }

  void _onAccessChanged() {
    final enabled = _enabled;
    // Ao virar assinante (ou ao abrir o app já assinante) envia tudo.
    if (enabled && !_wasEnabled) {
      unawaited(_loadLastBackupAt());
      _dirty = true;
      _schedule(const Duration(seconds: 3));
    }
    _wasEnabled = enabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _dirty) unawaited(backupNow());
  }

  /// Avisa que algum dado local mudou.
  void markDirty() {
    if (_restoring) return;
    _dirty = true;
    if (_enabled) _schedule(_debounce);
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(backupNow()));
  }

  /// Envia agora o que estiver pendente. Não lança: o erro fica em
  /// [lastError] e a próxima alteração tenta de novo.
  Future<void> backupNow() async {
    _timer?.cancel();
    if (!_enabled || _restoring) return;
    final current = _running;
    if (current != null) {
      // Já está enviando: garante mais uma rodada ao final.
      _dirty = true;
      await current;
      if (_dirty) return backupNow();
      return;
    }
    _dirty = false;
    final run = _run();
    _running = run;
    notifyListeners();
    try {
      await run;
      lastError = null;
    } on Object catch (error) {
      _dirty = true;
      lastError = tr.backupFailed;
      debugPrint('Falha no backup automático: $error');
    } finally {
      _running = null;
      notifyListeners();
    }
  }

  Future<void> _run() async {
    final uid = _auth.currentUser!.uid;
    final state = await _BackupState.load(uid);
    final local = await _collectLocal();

    // 1. Arquivos novos (fotos, comprovantes, PDFs).
    for (final entry in local.files.entries) {
      if (state.files.contains(entry.key)) continue;
      final file = File(entry.value);
      if (!await file.exists()) continue;
      await _fileRef(
        uid,
        entry.key,
      ).putFile(file, SettableMetadata(contentType: _contentType(entry.key)));
      state.files.add(entry.key);
      await state.save();
    }

    // 2. Registros novos, alterados e apagados.
    final operations = <MapEntry<String, String?>>[
      for (final entry in local.items.entries)
        if (state.items[entry.key] != entry.value) entry,
      for (final id in state.items.keys)
        if (!local.items.containsKey(id)) MapEntry(id, null),
    ];
    for (var start = 0; start < operations.length; start += _batchLimit) {
      final chunk = operations.skip(start).take(_batchLimit).toList();
      final batch = _firestore.batch();
      for (final operation in chunk) {
        final ref = _items(uid).doc(operation.key);
        final payload = operation.value;
        if (payload == null) {
          batch.delete(ref);
        } else {
          batch.set(ref, {
            'collection': operation.key.split('__').first,
            'payload': payload,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
      for (final operation in chunk) {
        if (operation.value == null) {
          state.items.remove(operation.key);
        } else {
          state.items[operation.key] = operation.value!;
        }
      }
      await state.save();
    }

    // 3. Arquivos que nenhum registro usa mais.
    final unused = state.files.where((key) => !local.files.containsKey(key));
    for (final key in unused.toList()) {
      try {
        await _fileRef(uid, key).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
      state.files.remove(key);
    }

    state.lastBackupAt = DateTime.now();
    await state.save();
    lastBackupAt = state.lastBackupAt;
  }

  /// Quantos registros existem na nuvem para a conta atual (0 se não houver
  /// conta ou a consulta falhar).
  Future<int> cloudItemCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;
    try {
      final result = await _items(uid).count().get();
      return result.count ?? 0;
    } on Object {
      return 0;
    }
  }

  /// Traz da nuvem todos os registros e arquivos e mescla com os dados do
  /// aparelho: cria o que não existe e atualiza pelo mesmo id. Nada local é
  /// apagado; o que só existe no aparelho é enviado em seguida.
  Future<int> restore() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(tr.backupSignInToRestore);
    }
    final uid = user.uid;
    _timer?.cancel();
    await _running;
    _restoring = true;
    notifyListeners();
    final temporary = Directory(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}mycarapp_restore',
    );
    try {
      final snapshot = await _items(uid).get();
      if (await temporary.exists()) await temporary.delete(recursive: true);
      await temporary.create(recursive: true);

      final downloaded = <String, String>{};
      Future<String?> download(String key) async {
        if (downloaded.containsKey(key)) return downloaded[key];
        final target = File(
          '${temporary.path}${Platform.pathSeparator}${key.replaceAll('/', '_')}',
        );
        try {
          await _fileRef(uid, key).writeToFile(target);
          downloaded[key] = target.path;
          return target.path;
        } on Object catch (error) {
          debugPrint('Arquivo do backup indisponível ($key): $error');
          return null;
        }
      }

      final byCollection = <String, List<Map<String, dynamic>>>{};
      final state = await _BackupState.load(uid);
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final collection = data['collection'] as String?;
        final payload = data['payload'] as String?;
        if (collection == null || payload == null) continue;
        state.items[doc.id] = payload;
        final json = jsonDecode(payload) as Map<String, dynamic>;
        final ok = await _resolveFiles(collection, json, download, state);
        if (ok) byCollection.putIfAbsent(collection, () => []).add(json);
      }

      // Locais antes dos registros que apontam para eles.
      for (final json in byCollection['establishments'] ?? const []) {
        await _establishments.saveEstablishment(Establishment.fromJson(json));
      }
      for (final json in byCollection['vehicles'] ?? const []) {
        await _vehicles.saveVehicle(Vehicle.fromJson(json));
      }
      for (final json in byCollection['fuelings'] ?? const []) {
        await _fuelings.saveFueling(FuelingRecord.fromJson(json));
      }
      for (final json in byCollection['maintenances'] ?? const []) {
        await _maintenances.saveMaintenance(MaintenanceRecord.fromJson(json));
      }
      for (final json in byCollection['expenses'] ?? const []) {
        await _expenses.saveExpense(VehicleExpense.fromJson(json));
      }
      for (final json in byCollection['documents'] ?? const []) {
        await _documents.restoreDocument(AppDocument.fromJson(json));
      }
      await state.save();
      return snapshot.docs.length;
    } finally {
      _restoring = false;
      if (await temporary.exists()) await temporary.delete(recursive: true);
      notifyListeners();
      // Envia o que só existia neste aparelho.
      markDirty();
    }
  }

  /// Troca `cloud:<chave>` pelo arquivo baixado. Anexos que não puderam ser
  /// baixados são descartados do registro; um documento sem o PDF é
  /// ignorado (retorna `false`).
  Future<bool> _resolveFiles(
    String collection,
    Map<String, dynamic> json,
    Future<String?> Function(String key) download,
    _BackupState state,
  ) async {
    Future<String?> resolve(Object? path) async {
      if (path is! String || !path.startsWith(_cloudPrefix)) return null;
      final key = path.substring(_cloudPrefix.length);
      final local = await download(key);
      if (local != null) state.files.add(key);
      return local;
    }

    if (collection == 'documents') {
      final local = await resolve(json['path']);
      if (local == null) return false;
      json['path'] = local;
      return true;
    }
    final field = switch (collection) {
      'vehicles' => 'photos',
      'fuelings' || 'maintenances' => 'attachments',
      _ => null,
    };
    if (field == null) return true;
    final kept = <Map<String, dynamic>>[];
    for (final item in (json[field] as List<dynamic>? ?? const [])) {
      final entry = Map<String, dynamic>.from(item as Map);
      final local = await resolve(entry['path']);
      if (local == null) continue;
      entry['path'] = local;
      kept.add(entry);
    }
    json[field] = kept;
    return true;
  }

  Future<_LocalSnapshot> _collectLocal() async {
    final snapshot = _LocalSnapshot();

    String cloudPath(String key, String localPath) {
      snapshot.files[key] = localPath;
      return '$_cloudPrefix$key';
    }

    for (final vehicle in await _vehicles.loadVehicles()) {
      final json = vehicle.toJson();
      json['photos'] = [
        for (final (index, photo) in vehicle.photos.indexed)
          {
            ...photo.toJson(),
            'path': cloudPath(
              'vehicles/${vehicle.id}/${photo.date.microsecondsSinceEpoch}_$index${_extension(photo.path)}',
              photo.path,
            ),
          },
      ];
      snapshot.add('vehicles', vehicle.id, json);
    }
    for (final record in await _fuelings.loadFuelings()) {
      final json = record.toJson();
      json['attachments'] = [
        for (final (index, item) in record.attachments.indexed)
          {
            ...item.toJson(),
            'path': cloudPath(
              'fuelings/${record.id}/${item.createdAt.microsecondsSinceEpoch}_$index${_extension(item.path)}',
              item.path,
            ),
          },
      ];
      snapshot.add('fuelings', record.id, json);
    }
    for (final record in await _maintenances.loadMaintenances()) {
      final json = record.toJson();
      json['attachments'] = [
        for (final (index, item) in record.attachments.indexed)
          {
            ...item.toJson(),
            'path': cloudPath(
              'maintenances/${record.id}/${item.createdAt.microsecondsSinceEpoch}_$index${_extension(item.path)}',
              item.path,
            ),
          },
      ];
      snapshot.add('maintenances', record.id, json);
    }
    for (final expense in await _expenses.loadExpenses()) {
      snapshot.add('expenses', expense.id, expense.toJson());
    }
    for (final item in await _establishments.loadEstablishments()) {
      snapshot.add('establishments', item.id, item.toJson());
    }
    for (final document in await _documents.loadDocuments()) {
      final json = document.toJson();
      json['path'] = cloudPath('documents/${document.id}.pdf', document.path);
      snapshot.add('documents', document.id, json);
    }
    return snapshot;
  }

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection('users').doc(uid).collection('backupItems');

  Reference _fileRef(String uid, String key) =>
      _storage.ref('users/$uid/files/$key');

  Future<void> _loadLastBackupAt() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    lastBackupAt = (await _BackupState.load(uid)).lastBackupAt;
    notifyListeners();
  }

  static String _extension(String path) {
    final lower = path.toLowerCase();
    for (final extension in ['.pdf', '.png', '.webp', '.jpeg']) {
      if (lower.endsWith(extension)) return extension;
    }
    return '.jpg';
  }

  static String _contentType(String key) => switch (_extension(key)) {
    '.pdf' => 'application/pdf',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

class _LocalSnapshot {
  /// Id do documento na nuvem (`colecao__id`) → JSON do registro.
  final Map<String, String> items = {};

  /// Chave do arquivo no Storage → caminho local.
  final Map<String, String> files = {};

  void add(String collection, String id, Map<String, dynamic> json) =>
      items['${collection}__$id'] = jsonEncode(json);
}

/// O que já está na nuvem, segundo este aparelho: o JSON enviado de cada
/// registro e as chaves dos arquivos enviados. Serve para enviar só o que
/// mudou e para saber o que apagar. Fica num arquivo local por conta.
class _BackupState {
  _BackupState(this._file, this.uid);

  final File _file;
  final String uid;
  Map<String, String> items = {};
  Set<String> files = {};
  DateTime? lastBackupAt;

  static Future<_BackupState> load(String uid) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    final state = _BackupState(
      File('${directory.path}${Platform.pathSeparator}cloud_backup_state.json'),
      uid,
    );
    try {
      if (!await state._file.exists()) return state;
      final json =
          jsonDecode(await state._file.readAsString()) as Map<String, dynamic>;
      // Outra conta neste aparelho: começa do zero para essa conta.
      if (json['uid'] != uid) return state;
      state.items = Map<String, String>.from(json['items'] as Map);
      state.files = (json['files'] as List<dynamic>).cast<String>().toSet();
      state.lastBackupAt = DateTime.tryParse(
        json['lastBackupAt'] as String? ?? '',
      );
    } on Object {
      // Estado ilegível: o próximo backup reenvia tudo.
    }
    return state;
  }

  Future<void> save() async {
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'uid': uid,
        'items': items,
        'files': files.toList(),
        'lastBackupAt': lastBackupAt?.toIso8601String(),
      }),
      flush: true,
    );
    await temporary.rename(_file.path);
  }
}
