import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/establishment.dart';
import '../models/fueling_record.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../models/vehicle_expense.dart';
import 'establishment_storage_service.dart';
import 'expense_storage_service.dart';
import 'fueling_storage_service.dart';
import 'maintenance_storage_service.dart';
import 'vehicle_storage_service.dart';

/// Resumo de um backup, sem precisar baixar o arquivo inteiro do Storage —
/// vem dos metadados gravados em `users/{uid}/backups/{id}` no Firestore.
class BackupSummary {
  const BackupSummary({
    required this.id,
    required this.createdAt,
    required this.counts,
    required this.sizeBytes,
  });

  final String id;
  final DateTime createdAt;
  final Map<String, int> counts;
  final int sizeBytes;

  int get totalRecords => counts.values.fold(0, (sum, value) => sum + value);
}

/// Quantos registros um backup adicionaria (novos) ou atualizaria
/// (já existem localmente com o mesmo id) se fosse restaurado agora.
class RestoreImpact {
  const RestoreImpact({required this.added, required this.updated});
  final int added;
  final int updated;

  int get total => added + updated;
}

/// Backup Premium em nuvem (Seção 4.2 do guia de planejamento; Fase 6 da
/// trilha de implementação).
///
/// Cobre apenas dados estruturados — veículos, abastecimentos, despesas,
/// manutenções e locais cadastrados. Fotos e documentos anexados **não**
/// fazem parte desta versão (ver decisão registrada na trilha): são
/// arquivos, não registros JSON, e restaurá-los exigiria também
/// upload/download dos binários, escopo maior que o desta primeira entrega.
///
/// O acesso é sempre verificado no servidor: o cliente só consegue gravar
/// em `users/{uid}/backups/...` (Storage e Firestore) se `isPremium` for
/// verdadeiro nas regras — ver `storage.rules` e `firestore.rules`. Este
/// serviço nunca decide por si só se o usuário pode fazer backup; ele só
/// tenta, e a regra do servidor aceita ou nega.
class CloudBackupService {
  CloudBackupService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  final _vehicleStorage = VehicleStorageService();
  final _fuelingStorage = FuelingStorageService();
  final _expenseStorage = ExpenseStorageService();
  final _maintenanceStorage = MaintenanceStorageService();
  final _establishmentStorage = EstablishmentStorageService();

  /// Mantém apenas os backups mais recentes. Simplificação da janela
  /// 7 diárias / 4 semanais / 3 mensais do guia (que exigiria classificar
  /// backups por idade, algo mais natural de fazer num job agendado no
  /// servidor do que no cliente) — ver decisão registrada na trilha.
  static const _keepCount = 10;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Entre com sua conta para usar o backup em nuvem.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _backupsCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('backups');

  Future<Map<String, dynamic>> _buildPayloadData() async {
    final vehicles = (await _vehicleStorage.loadVehicles())
        .map((item) => item.copyWith(photos: const []))
        .toList();
    final fuelings = (await _fuelingStorage.loadFuelings())
        .map((item) => item.copyWith(attachments: const []))
        .toList();
    final expenses = await _expenseStorage.loadExpenses();
    final maintenances = (await _maintenanceStorage.loadMaintenances())
        .map((item) => item.copyWith(attachments: const []))
        .toList();
    final establishments = await _establishmentStorage.loadEstablishments();

    return {
      'vehicles': vehicles.map((item) => item.toJson()).toList(),
      'fuelings': fuelings.map((item) => item.toJson()).toList(),
      'expenses': expenses.map((item) => item.toJson()).toList(),
      'maintenances': maintenances.map((item) => item.toJson()).toList(),
      'establishments': establishments.map((item) => item.toJson()).toList(),
    };
  }

  /// Gera um novo backup a partir dos dados locais e envia para o Storage.
  /// Falha com [StateError] (sem conta) ou com o erro do Firebase se a
  /// regra do servidor negar (ex.: usuário não é Premium).
  Future<BackupSummary> createBackup() async {
    final uid = _uid;
    final data = await _buildPayloadData();
    final counts = data.map(
      (key, value) => MapEntry(key, (value as List<dynamic>).length),
    );
    final createdAt = DateTime.now();
    final id = createdAt.millisecondsSinceEpoch.toString();
    final payload = jsonEncode({
      'schemaVersion': 1,
      'createdAt': createdAt.toIso8601String(),
      'counts': counts,
      'data': data,
    });
    final bytes = Uint8List.fromList(utf8.encode(payload));

    final ref = _storage.ref('users/$uid/backups/$id.json');
    await ref.putData(bytes, SettableMetadata(contentType: 'application/json'));

    await _backupsCollection(uid).doc(id).set({
      'counts': counts,
      'sizeBytes': bytes.length,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _pruneOldBackups(uid);

    return BackupSummary(
      id: id,
      createdAt: createdAt,
      counts: counts,
      sizeBytes: bytes.length,
    );
  }

  Future<List<BackupSummary>> listBackups() async {
    final uid = _uid;
    final snapshot = await _backupsCollection(
      uid,
    ).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(_summaryFromDoc).toList();
  }

  /// Igual a [listBackups], mas nunca lança: retorna lista vazia se o
  /// usuário não estiver logado ou a consulta falhar. Útil para cards de
  /// status que não devem quebrar a tela por causa do backup.
  Future<List<BackupSummary>> listBackupsSafely() async {
    if (_auth.currentUser == null) return const [];
    try {
      return await listBackups();
    } on Object {
      return const [];
    }
  }

  BackupSummary _summaryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final rawCounts = Map<String, dynamic>.from(
      data['counts'] as Map<String, dynamic>? ?? {},
    );
    return BackupSummary(
      id: doc.id,
      createdAt: createdAt,
      counts: rawCounts.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      sizeBytes: (data['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _pruneOldBackups(String uid) async {
    final backups = await listBackups();
    if (backups.length <= _keepCount) return;
    for (final backup in backups.skip(_keepCount)) {
      try {
        await _storage.ref('users/$uid/backups/${backup.id}.json').delete();
      } on Object {
        // Se o arquivo já não existir no Storage, seguimos removendo o
        // metadado mesmo assim — não deixar lixo de metadado órfão.
      }
      await _backupsCollection(uid).doc(backup.id).delete();
    }
  }

  Future<Map<String, dynamic>> _downloadPayload(String backupId) async {
    final uid = _uid;
    final ref = _storage.ref('users/$uid/backups/$backupId.json');
    final bytes = await ref.getData(20 * 1024 * 1024);
    if (bytes == null) {
      throw StateError('Backup não encontrado no Storage.');
    }
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  /// Compara o backup com os dados locais atuais sem alterar nada — usado
  /// para mostrar o resumo de impacto antes de confirmar a restauração.
  Future<RestoreImpact> previewRestore(String backupId) async {
    final payload = await _downloadPayload(backupId);
    final data = payload['data'] as Map<String, dynamic>? ?? {};

    final localIds = <String, Set<String>>{
      'vehicles': (await _vehicleStorage.loadVehicles())
          .map((item) => item.id)
          .toSet(),
      'fuelings': (await _fuelingStorage.loadFuelings())
          .map((item) => item.id)
          .toSet(),
      'expenses': (await _expenseStorage.loadExpenses())
          .map((item) => item.id)
          .toSet(),
      'maintenances': (await _maintenanceStorage.loadMaintenances())
          .map((item) => item.id)
          .toSet(),
      'establishments': (await _establishmentStorage.loadEstablishments())
          .map((item) => item.id)
          .toSet(),
    };

    var added = 0;
    var updated = 0;
    for (final entry in localIds.entries) {
      final items = data[entry.key] as List<dynamic>? ?? const [];
      for (final item in items) {
        final id = (item as Map<String, dynamic>)['id'] as String?;
        if (id != null && entry.value.contains(id)) {
          updated++;
        } else {
          added++;
        }
      }
    }
    return RestoreImpact(added: added, updated: updated);
  }

  /// Mescla o backup com os dados locais: cria o que não existe e
  /// atualiza o que já existe pelo mesmo id. **Nunca apaga** nada — é o
  /// único modo de restauração desta versão (a opção "substituir tudo" do
  /// guia fica para uma próxima iteração, ver decisão na trilha).
  ///
  /// Antes de aplicar qualquer alteração, cria automaticamente um novo
  /// backup do estado atual, para permitir desfazer manualmente se algo
  /// sair errado (mesma exigência do guia para a restauração).
  Future<void> restoreMerge(String backupId) async {
    await createBackup();

    final payload = await _downloadPayload(backupId);
    final data = payload['data'] as Map<String, dynamic>? ?? {};

    for (final item in (data['vehicles'] as List<dynamic>? ?? const [])) {
      await _vehicleStorage.saveVehicle(
        Vehicle.fromJson(item as Map<String, dynamic>),
      );
    }
    for (final item in (data['fuelings'] as List<dynamic>? ?? const [])) {
      await _fuelingStorage.saveFueling(
        FuelingRecord.fromJson(item as Map<String, dynamic>),
      );
    }
    for (final item in (data['expenses'] as List<dynamic>? ?? const [])) {
      await _expenseStorage.saveExpense(
        VehicleExpense.fromJson(item as Map<String, dynamic>),
      );
    }
    for (final item in (data['maintenances'] as List<dynamic>? ?? const [])) {
      await _maintenanceStorage.saveMaintenance(
        MaintenanceRecord.fromJson(item as Map<String, dynamic>),
      );
    }
    for (final item in (data['establishments'] as List<dynamic>? ?? const [])) {
      await _establishmentStorage.saveEstablishment(
        Establishment.fromJson(item as Map<String, dynamic>),
      );
    }
  }
}
