import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/vehicle_expense.dart';

class ExpenseStorageService {
  static Future<void> _writeQueue = Future.value();

  Future<File> _dataFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}expenses.json');
  }

  Future<List<VehicleExpense>> loadExpenses() async {
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
          .map((item) => VehicleExpense.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Object {
      throw const FileSystemException(
        'O arquivo local de despesas está corrompido.',
      );
    }
  }

  Future<void> saveExpense(VehicleExpense expense) => _serialized(() async {
    final expenses = await loadExpenses();
    final index = expenses.indexWhere((item) => item.id == expense.id);
    if (index < 0) {
      expenses.add(expense);
    } else {
      expenses[index] = expense;
    }
    await _write(expenses);
  });

  Future<void> deleteExpense(String id) => _serialized(() async {
    final expenses = await loadExpenses();
    expenses.removeWhere((item) => item.id == id);
    await _write(expenses);
  });

  Future<void> _write(List<VehicleExpense> expenses) async {
    final file = await _dataFile();
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temporary.writeAsString(
      jsonEncode(expenses.map((item) => item.toJson()).toList()),
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
