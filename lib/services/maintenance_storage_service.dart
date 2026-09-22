import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/maintenance_record.dart';
import 'attachment_storage_service.dart';

class MaintenanceStorageService {
  static Future<void> _writeQueue = Future.value();
  final attachmentStorage = AttachmentStorageService();

  Future<File> _dataFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}maintenances.json');
  }

  Future<List<MaintenanceRecord>> loadMaintenances() async {
    final file = await _dataFile();
    final backup = File('${file.path}.bak');
    if (!await file.exists() && await backup.exists()) {
      await backup.copy(file.path);
    }
    if (!await file.exists()) return [];
    try {
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      final decoded = jsonDecode(contents);
      if (decoded is! List<dynamic>) throw const FormatException();
      return decoded
          .map(
            (item) => MaintenanceRecord.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on Object {
      throw const FileSystemException(
        'O arquivo local de manutenções está corrompido.',
      );
    }
  }

  Future<void> saveMaintenance(MaintenanceRecord record) =>
      _serialized(() async {
        final attachments = await attachmentStorage.persist(
          collection: 'maintenances',
          recordId: record.id,
          attachments: record.attachments,
        );
        final savedRecord = record.copyWith(attachments: attachments);
        final records = await loadMaintenances();
        final index = records.indexWhere((item) => item.id == record.id);
        if (index < 0) {
          records.add(savedRecord);
        } else {
          records[index] = savedRecord;
        }
        await _writeRecords(records);
      });

  Future<void> deleteMaintenance(String recordId) => _serialized(() async {
    final records = await loadMaintenances();
    records.removeWhere((item) => item.id == recordId);
    await _writeRecords(records);
    await attachmentStorage.deleteRecord(
      collection: 'maintenances',
      recordId: recordId,
    );
  });

  Future<void> _writeRecords(List<MaintenanceRecord> records) async {
    final file = await _dataFile();
    await _writeJsonSafely(file, records.map((item) => item.toJson()).toList());
  }

  Future<void> _writeJsonSafely(File file, Object value) async {
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temporary.writeAsString(jsonEncode(value), flush: true);
    if (await backup.exists()) await backup.delete();
    if (await file.exists()) await file.rename(backup.path);
    try {
      await temporary.rename(file.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (!await file.exists() && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    }
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }
}
