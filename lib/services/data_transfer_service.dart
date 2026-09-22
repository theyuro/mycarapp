import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/fueling_record.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import 'fueling_storage_service.dart';
import 'maintenance_storage_service.dart';
import 'vehicle_storage_service.dart';

class DataTransferService {
  final vehicleStorage = VehicleStorageService();
  final fuelingStorage = FuelingStorageService();
  final maintenanceStorage = MaintenanceStorageService();

  Future<File> exportVehicle(String format) async {
    final vehicle = await vehicleStorage.loadActiveVehicle();
    if (vehicle == null) throw StateError('Nenhum veículo ativo.');
    final fuelings = (await fuelingStorage.loadFuelings())
        .where((item) => item.vehicleId == vehicle.id)
        .toList();
    final maintenances = (await maintenanceStorage.loadMaintenances())
        .where((item) => item.vehicleId == vehicle.id)
        .toList();
    final rows = <_TransferRow>[
      _TransferRow('manifest', {
        'format': 'mycarapp-transfer',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
      }),
      _TransferRow('vehicle', {...vehicle.toJson(), 'photos': <Object>[]}),
      ...fuelings.map(
        (item) => _TransferRow('fueling', {
          ...item.toJson(),
          'attachments': <Object>[],
        }),
      ),
      ...maintenances.map(
        (item) => _TransferRow('maintenance', {
          ...item.toJson(),
          'attachments': <Object>[],
        }),
      ),
    ];
    final temporary = await getTemporaryDirectory();
    final safeName = vehicle.nickname
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .toLowerCase();
    if (format == 'xlsx') {
      final excel = Excel.createExcel();
      final sheet = excel['MyCarApp'];
      sheet.appendRow([TextCellValue('tipo'), TextCellValue('dados')]);
      for (final row in rows) {
        sheet.appendRow([
          TextCellValue(row.type),
          TextCellValue(base64Encode(utf8.encode(jsonEncode(row.data)))),
        ]);
      }
      final bytes = excel.encode();
      if (bytes == null)
        throw const FileSystemException('Falha ao gerar Excel.');
      final file = File(
        '${temporary.path}${Platform.pathSeparator}mycarapp_$safeName.xlsx',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
    final buffer = StringBuffer('tipo,dados\n');
    for (final row in rows) {
      buffer.writeln(
        '${row.type},${base64Encode(utf8.encode(jsonEncode(row.data)))}',
      );
    }
    final file = File(
      '${temporary.path}${Platform.pathSeparator}mycarapp_$safeName.csv',
    );
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  Future<ImportSummary> importFile(String path) async {
    final rows = path.toLowerCase().endsWith('.xlsx')
        ? await _readExcel(path)
        : await _readCsv(path);
    final manifest = rows.where((item) => item.type == 'manifest').firstOrNull;
    if (manifest?.data['format'] != 'mycarapp-transfer') {
      throw const FormatException('Arquivo não reconhecido pelo MyCarApp.');
    }
    final vehicleRow = rows.where((item) => item.type == 'vehicle').firstOrNull;
    if (vehicleRow == null) throw const FormatException('Veículo ausente.');
    final originalVehicle = Vehicle.fromJson(vehicleRow.data);
    final newVehicleId = '${DateTime.now().microsecondsSinceEpoch}';
    final importedVehicle = Vehicle(
      id: newVehicleId,
      nickname: originalVehicle.nickname,
      brand: originalVehicle.brand,
      model: originalVehicle.model,
      year: originalVehicle.year,
      fuel: originalVehicle.fuel,
      transmission: originalVehicle.transmission,
      mileage: originalVehicle.mileage,
      createdAt: DateTime.now(),
      documents: originalVehicle.documents,
      photos: const [],
      vehicleType: originalVehicle.vehicleType,
    );
    await vehicleStorage.saveVehicle(importedVehicle);
    var fuelCount = 0;
    var maintenanceCount = 0;
    for (final row in rows) {
      if (row.type == 'fueling') {
        final data = {...row.data};
        data['id'] = '${newVehicleId}_f_$fuelCount';
        data['vehicleId'] = newVehicleId;
        data['attachments'] = <Object>[];
        await fuelingStorage.saveFueling(FuelingRecord.fromJson(data));
        fuelCount++;
      } else if (row.type == 'maintenance') {
        final data = {...row.data};
        data['id'] = '${newVehicleId}_m_$maintenanceCount';
        data['vehicleId'] = newVehicleId;
        data['attachments'] = <Object>[];
        await maintenanceStorage.saveMaintenance(
          MaintenanceRecord.fromJson(data),
        );
        maintenanceCount++;
      }
    }
    await vehicleStorage.setActiveVehicle(newVehicleId);
    return ImportSummary(
      vehicleName: importedVehicle.nickname,
      fuelings: fuelCount,
      maintenances: maintenanceCount,
    );
  }

  Future<List<_TransferRow>> _readCsv(String path) async {
    final lines = await File(path).readAsLines();
    return lines.skip(1).where((line) => line.trim().isNotEmpty).map((line) {
      final comma = line.indexOf(',');
      if (comma < 1) throw const FormatException('Linha CSV inválida.');
      return _decodeRow(line.substring(0, comma), line.substring(comma + 1));
    }).toList();
  }

  Future<List<_TransferRow>> _readExcel(String path) async {
    final excel = Excel.decodeBytes(await File(path).readAsBytes());
    if (excel.tables.isEmpty) throw const FormatException('Planilha vazia.');
    final table = excel.tables.values.first;
    return table.rows.skip(1).where((row) => row.length >= 2).map((row) {
      final type = row[0]?.value?.toString() ?? '';
      final payload = row[1]?.value?.toString() ?? '';
      return _decodeRow(type, payload);
    }).toList();
  }

  _TransferRow _decodeRow(String type, String payload) => _TransferRow(
    type,
    jsonDecode(utf8.decode(base64Decode(payload))) as Map<String, dynamic>,
  );
}

class ImportSummary {
  const ImportSummary({
    required this.vehicleName,
    required this.fuelings,
    required this.maintenances,
  });
  final String vehicleName;
  final int fuelings;
  final int maintenances;
}

class _TransferRow {
  const _TransferRow(this.type, this.data);
  final String type;
  final Map<String, dynamic> data;
}
