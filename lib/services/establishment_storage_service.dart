import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/establishment.dart';

/// Armazenamento local dos estabelecimentos (postos, oficinas etc.).
///
/// Nunca sincroniza com a nuvem: o cadastro de estabelecimentos segue a
/// regra de que apenas dados sincronizados em nuvem exigem Premium, e o
/// cadastro em si é local para todos os usuários.
class EstablishmentStorageService {
  static Future<void> _writeQueue = Future.value();

  Future<File> _dataFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}establishments.json',
    );
  }

  Future<List<Establishment>> loadEstablishments() async {
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
          .map((item) => Establishment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Object {
      throw const FileSystemException(
        'O arquivo local de estabelecimentos está corrompido.',
      );
    }
  }

  Future<List<Establishment>> loadActiveEstablishments({
    EstablishmentType? type,
  }) async {
    final all = await loadEstablishments();
    final filtered = all.where((item) => item.active);
    if (type == null) return filtered.toList();
    return filtered.where((item) => item.type == type).toList();
  }

  Future<Establishment> saveEstablishment(Establishment establishment) =>
      _serialized(() async {
        final establishments = await loadEstablishments();
        final index = establishments.indexWhere(
          (item) => item.id == establishment.id,
        );
        if (index < 0) {
          establishments.add(establishment);
        } else {
          establishments[index] = establishment;
        }
        await _write(establishments);
        return establishment;
      });

  /// Cria um novo estabelecimento apenas com nome e tipo, para o fluxo
  /// "+ Novo" dentro dos formulários de lançamento.
  Future<Establishment> createQuick({
    required String name,
    required EstablishmentType type,
  }) {
    final now = DateTime.now();
    final establishment = Establishment(
      id: '${now.microsecondsSinceEpoch}',
      name: name.trim(),
      type: type,
      createdAt: now,
      updatedAt: now,
    );
    return saveEstablishment(establishment);
  }

  Future<void> deleteEstablishment(String id) => _serialized(() async {
    final establishments = await loadEstablishments();
    establishments.removeWhere((item) => item.id == id);
    await _write(establishments);
  });

  Future<void> _write(List<Establishment> establishments) async {
    final file = await _dataFile();
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temporary.writeAsString(
      jsonEncode(establishments.map((item) => item.toJson()).toList()),
      flush: true,
    );
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
