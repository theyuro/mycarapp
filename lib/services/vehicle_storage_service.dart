import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/vehicle.dart';
import 'auto_backup_service.dart';
import '../l10n/l10n.dart';

class VehicleStorageService {
  static Future<void> _writeQueue = Future.value();

  /// Quantidade de veículos salvos, sincronizada a cada leitura e gravação;
  /// o Analytics acompanha para manter a propriedade `vehicles_count`.
  static final vehicleCount = ValueNotifier<int>(0);

  Future<Directory> _rootDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _vehiclesFile() async {
    final root = await _rootDirectory();
    return File('${root.path}${Platform.pathSeparator}vehicles.json');
  }

  Future<File> _activeVehicleFile() async {
    final root = await _rootDirectory();
    return File('${root.path}${Platform.pathSeparator}active_vehicle.json');
  }

  Future<List<Vehicle>> loadVehicles() async {
    final file = await _vehiclesFile();
    final backup = File('${file.path}.bak');
    if (!await file.exists() && await backup.exists()) {
      await backup.copy(file.path);
    }
    if (!await file.exists()) {
      vehicleCount.value = 0;
      return [];
    }

    try {
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        vehicleCount.value = 0;
        return [];
      }
      final decoded = jsonDecode(contents);
      if (decoded is! List<dynamic>) throw const FormatException();
      final vehicles = decoded
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();
      // Mantém o notificador em sincronia com o disco a cada leitura, não só
      // na gravação (senão a abertura do app não reflete a contagem real).
      vehicleCount.value = vehicles.length;
      return vehicles;
    } on Object {
      throw FileSystemException(tr.storageVehiclesCorrupted);
    }
  }

  Future<Vehicle?> loadActiveVehicle() async {
    final vehicles = await loadVehicles();
    if (vehicles.isEmpty) return null;

    final activeFile = await _activeVehicleFile();
    if (await activeFile.exists()) {
      try {
        final decoded = jsonDecode(await activeFile.readAsString());
        final activeId = (decoded as Map<String, dynamic>)['vehicleId'];
        for (final vehicle in vehicles) {
          if (vehicle.id == activeId) return vehicle;
        }
      } on Object {
        // Um arquivo de seleção inválido é recriado abaixo.
      }
    }

    await setActiveVehicle(vehicles.first.id);
    return vehicles.first;
  }

  Future<void> setActiveVehicle(String vehicleId) => _serialized(() async {
    final vehicles = await loadVehicles();
    if (!vehicles.any((vehicle) => vehicle.id == vehicleId)) {
      throw ArgumentError.value(vehicleId, 'vehicleId', 'Veículo inexistente');
    }
    final file = await _activeVehicleFile();
    await _writeJsonSafely(file, {'vehicleId': vehicleId});
  });

  Future<Vehicle> saveVehicle(Vehicle vehicle) => _serialized(() async {
    final root = await _rootDirectory();
    final vehicleDirectory = Directory(
      '${root.path}${Platform.pathSeparator}vehicles${Platform.pathSeparator}${vehicle.id}',
    );
    final photoDirectory = Directory(
      '${vehicleDirectory.path}${Platform.pathSeparator}photos',
    );
    await photoDirectory.create(recursive: true);

    final permanentPhotos = <VehiclePhoto>[];
    for (var index = 0; index < vehicle.photos.length; index++) {
      final photo = vehicle.photos[index];
      final source = File(photo.path);
      if (!await source.exists()) {
        throw FileSystemException(tr.storagePhotoNotFound, photo.path);
      }
      if (source.parent.path == photoDirectory.path) {
        permanentPhotos.add(photo);
        continue;
      }
      final filename =
          '${photo.date.microsecondsSinceEpoch}_$index${_extensionOf(photo.path)}';
      final destination = File(
        '${photoDirectory.path}${Platform.pathSeparator}$filename',
      );
      await source.copy(destination.path);
      permanentPhotos.add(
        VehiclePhoto(destination.path, photo.type, photo.date),
      );
    }

    final savedVehicle = vehicle.copyWith(photos: permanentPhotos);
    final vehicles = await loadVehicles();
    final index = vehicles.indexWhere((item) => item.id == vehicle.id);
    if (index < 0) {
      vehicles.add(savedVehicle);
    } else {
      vehicles[index] = savedVehicle;
    }
    await _writeVehicles(vehicles);

    if (vehicles.length == 1) await _writeActiveId(savedVehicle.id);
    await _removeUnusedPhotos(photoDirectory, permanentPhotos);
    return savedVehicle;
  });

  /// Atualiza a quilometragem do veículo quando um registro informa um valor
  /// maior. Nunca reduz: registros antigos ou digitados a menos são ignorados.
  /// Retorna o veículo atualizado, ou null se nada mudou.
  Future<Vehicle?> raiseMileage(String vehicleId, int mileage) =>
      _serialized(() async {
        final vehicles = await loadVehicles();
        final index = vehicles.indexWhere((item) => item.id == vehicleId);
        if (index < 0 || mileage <= vehicles[index].mileage) return null;
        final updated = vehicles[index].copyWith(mileage: mileage);
        vehicles[index] = updated;
        await _writeVehicles(vehicles);
        return updated;
      });

  Future<void> deleteVehicle(String vehicleId) => _serialized(() async {
    final vehicles = await loadVehicles();
    final activeId = await _readActiveId();
    vehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
    await _writeVehicles(vehicles);

    if (activeId == vehicleId ||
        !vehicles.any((vehicle) => vehicle.id == activeId)) {
      if (vehicles.isEmpty) {
        final file = await _activeVehicleFile();
        if (await file.exists()) await file.delete();
      } else {
        await _writeActiveId(vehicles.first.id);
      }
    }

    final root = await _rootDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}vehicles${Platform.pathSeparator}$vehicleId',
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<String?> _readActiveId() async {
    final file = await _activeVehicleFile();
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      return (decoded as Map<String, dynamic>)['vehicleId'] as String?;
    } on Object {
      return null;
    }
  }

  Future<void> _writeVehicles(List<Vehicle> vehicles) async {
    AutoBackupService.instance.markDirty();
    vehicleCount.value = vehicles.length;
    final file = await _vehiclesFile();
    await _writeJsonSafely(
      file,
      vehicles.map((vehicle) => vehicle.toJson()).toList(),
    );
  }

  Future<void> _writeActiveId(String vehicleId) async {
    final file = await _activeVehicleFile();
    await _writeJsonSafely(file, {'vehicleId': vehicleId});
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

  Future<void> _removeUnusedPhotos(
    Directory directory,
    List<VehiclePhoto> photos,
  ) async {
    final usedPaths = photos.map((photo) => photo.path).toSet();
    await for (final entity in directory.list()) {
      if (entity is File && !usedPaths.contains(entity.path)) {
        await entity.delete();
      }
    }
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }

  String _extensionOf(String path) {
    final filename = path.split(RegExp(r'[/\\]')).last;
    final dot = filename.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final extension = filename.substring(dot).toLowerCase();
    return extension.length <= 6 ? extension : '.jpg';
  }
}
