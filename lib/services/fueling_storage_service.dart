import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/fueling_record.dart';
import 'attachment_storage_service.dart';

class FuelingStorageService {
  static Future<void> _writeQueue = Future.value();
  final attachmentStorage = AttachmentStorageService();

  Future<File> _dataFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}fuelings.json');
  }

  Future<List<FuelingRecord>> loadFuelings() async {
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
          .map((item) => FuelingRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Object {
      throw const FileSystemException(
        'O arquivo local de abastecimentos está corrompido.',
      );
    }
  }

  Future<void> addFueling(FuelingRecord record) {
    return saveFueling(record);
  }

  Future<void> saveFueling(FuelingRecord record) {
    final operation = _writeQueue.then((_) async {
      final attachments = await attachmentStorage.persist(
        collection: 'fuelings',
        recordId: record.id,
        attachments: record.attachments,
      );
      final savedRecord = record.copyWith(attachments: attachments);
      final records = await loadFuelings();
      final index = records.indexWhere((item) => item.id == record.id);
      if (index < 0) {
        records.add(savedRecord);
      } else {
        records[index] = savedRecord;
      }
      await _writeRecords(records);
    });
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }

  Future<void> deleteFueling(String recordId) {
    final operation = _writeQueue.then((_) async {
      final records = await loadFuelings();
      records.removeWhere((item) => item.id == recordId);
      await _writeRecords(records);
      await attachmentStorage.deleteRecord(
        collection: 'fuelings',
        recordId: recordId,
      );
    });
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }

  Future<void> _writeRecords(List<FuelingRecord> records) async {
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
}
