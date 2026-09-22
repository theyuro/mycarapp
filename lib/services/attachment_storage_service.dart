import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/record_attachment.dart';

class AttachmentStorageService {
  Future<void> deleteRecord({
    required String collection,
    required String recordId,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp${Platform.pathSeparator}attachments${Platform.pathSeparator}$collection${Platform.pathSeparator}$recordId',
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<List<RecordAttachment>> persist({
    required String collection,
    required String recordId,
    required List<RecordAttachment> attachments,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp${Platform.pathSeparator}attachments${Platform.pathSeparator}$collection${Platform.pathSeparator}$recordId',
    );
    await directory.create(recursive: true);
    final saved = <RecordAttachment>[];
    for (var index = 0; index < attachments.length; index++) {
      final attachment = attachments[index];
      final source = File(attachment.path);
      if (!await source.exists()) {
        throw FileSystemException('Anexo não encontrado', attachment.path);
      }
      if (source.parent.path == directory.path) {
        saved.add(attachment);
        continue;
      }
      final extension = attachment.isPdf
          ? '.pdf'
          : _imageExtension(source.path);
      final destination = File(
        '${directory.path}${Platform.pathSeparator}${attachment.createdAt.microsecondsSinceEpoch}_$index$extension',
      );
      await source.copy(destination.path);
      saved.add(attachment.copyWith(path: destination.path));
    }
    final used = saved.map((item) => item.path).toSet();
    await for (final entity in directory.list()) {
      if (entity is File && !used.contains(entity.path)) await entity.delete();
    }
    return saved;
  }

  String _imageExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    return '.jpg';
  }
}
