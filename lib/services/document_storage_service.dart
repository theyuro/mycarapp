import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_document.dart';

class DocumentStorageService {
  static Future<void> _writeQueue = Future.value();

  Future<Directory> _directory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp${Platform.pathSeparator}documents',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _dataFile() async {
    final directory = await _directory();
    return File('${directory.path}${Platform.pathSeparator}documents.json');
  }

  Future<List<AppDocument>> loadDocuments() async {
    final file = await _dataFile();
    if (!await file.exists()) return [];
    final contents = await file.readAsString();
    if (contents.trim().isEmpty) return [];
    final decoded = jsonDecode(contents) as List<dynamic>;
    return decoded
        .map((item) => AppDocument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AppDocument> importPdf({
    required String sourcePath,
    required String originalName,
    required String type,
    String? vehicleId,
  }) => _serialized(() async {
    final signature = await File(sourcePath)
        .openRead(0, 5)
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    if (signature.length < 5 || String.fromCharCodes(signature) != '%PDF-') {
      throw const FormatException('O arquivo selecionado não é um PDF válido.');
    }

    final records = await loadDocuments();
    final existing = records.where(
      (item) => item.type == type && item.vehicleId == vehicleId,
    );
    for (final item in existing) {
      final oldFile = File(item.path);
      if (await oldFile.exists()) await oldFile.delete();
    }
    records.removeWhere(
      (item) => item.type == type && item.vehicleId == vehicleId,
    );

    final now = DateTime.now();
    final directory = await _directory();
    final safeVehicle = vehicleId ?? 'owner';
    final destination = File(
      '${directory.path}${Platform.pathSeparator}${type}_${safeVehicle}_${now.microsecondsSinceEpoch}.pdf',
    );
    await File(sourcePath).copy(destination.path);
    final document = AppDocument(
      id: '${now.microsecondsSinceEpoch}',
      type: type,
      vehicleId: vehicleId,
      path: destination.path,
      originalName: originalName,
      importedAt: now,
    );
    records.add(document);
    await _write(records);
    return document;
  });

  Future<void> deleteDocument(AppDocument document) => _serialized(() async {
    final records = await loadDocuments();
    records.removeWhere((item) => item.id == document.id);
    final file = File(document.path);
    if (await file.exists()) await file.delete();
    await _write(records);
  });

  Future<void> _write(List<AppDocument> records) async {
    final file = await _dataFile();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(records.map((item) => item.toJson()).toList()),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }
}
