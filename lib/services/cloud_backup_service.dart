import 'dart:convert';

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
import '../l10n/l10n.dart';

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

/// Cópias manuais do backup em nuvem, feitas por versões anteriores do app
/// (um JSON por cópia no Storage, com metadados no Firestore). Hoje o
/// backup é automático ([AutoBackupService]); este serviço só lista e
/// restaura essas cópias antigas, o que continua liberado para o dono da
/// conta mesmo sem assinatura.
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

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError(tr.backupSignInRequired);
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _backupsCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('backups');

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

  Future<Map<String, dynamic>> _downloadPayload(String backupId) async {
    final uid = _uid;
    final ref = _storage.ref('users/$uid/backups/$backupId.json');
    final bytes = await ref.getData(20 * 1024 * 1024);
    if (bytes == null) {
      throw StateError(tr.backupNotFound);
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
  /// atualiza o que já existe pelo mesmo id. **Nunca apaga** nada.
  Future<void> restoreMerge(String backupId) async {
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
