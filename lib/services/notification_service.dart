import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_notification.dart';

class NotificationService {
  static const _channel = MethodChannel('mycarapp/notifications');
  static Future<void> _writeQueue = Future.value();

  Future<File> _dataFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}notifications.json');
  }

  Future<File> _settingsFile() async {
    final data = await _dataFile();
    return File(
      '${data.parent.path}${Platform.pathSeparator}notification_settings.json',
    );
  }

  Future<NotificationPreferences> loadPreferences() async {
    final file = await _settingsFile();
    if (!await file.exists()) return const NotificationPreferences();
    try {
      return NotificationPreferences.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return const NotificationPreferences();
    }
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(preferences.toJson()), flush: true);
    try {
      await _channel.invokeMethod<void>('setPreferences', preferences.toJson());
    } on MissingPluginException {
      // As preferências internas continuam válidas.
    }
  }

  Future<List<AppNotification>> loadNotifications() async {
    final file = await _dataFile();
    if (!await file.exists()) return [];
    final contents = await file.readAsString();
    if (contents.trim().isEmpty) return [];
    final decoded = jsonDecode(contents) as List<dynamic>;
    final items = decoded
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<bool> addUnique({
    required String key,
    required String title,
    required String message,
    bool showSystemNotification = true,
    String category = 'updates',
  }) => _serialized(() async {
    final preferences = await loadPreferences();
    if (!preferences.allows(category)) return false;
    final records = await loadNotifications();
    if (records.any((item) => item.key == key)) return false;
    final now = DateTime.now();
    records.add(
      AppNotification(
        id: '${now.microsecondsSinceEpoch}',
        key: key,
        title: title,
        message: message,
        createdAt: now,
      ),
    );
    await _write(records);
    if (showSystemNotification) {
      try {
        await _channel.invokeMethod<void>('show', {
          'title': title,
          'message': message,
        });
      } on MissingPluginException {
        // A central interna continua disponível em plataformas sem suporte nativo.
      }
    }
    return true;
  });

  Future<void> requestPermission() async {
    final preferences = await loadPreferences();
    if (!preferences.anyEnabled) return;
    try {
      await _channel.invokeMethod<void>('requestPermission');
    } on MissingPluginException {
      // Sem ação em plataformas sem suporte nativo.
    }
  }

  Future<void> scheduleMaintenance({
    required String id,
    required DateTime date,
    required String service,
  }) async {
    final preferences = await loadPreferences();
    if (!preferences.maintenance) return;
    try {
      await _channel.invokeMethod<void>('scheduleMaintenance', {
        'id': id,
        'date': DateTime(
          date.year,
          date.month,
          date.day,
          9,
        ).millisecondsSinceEpoch,
        'message': service,
      });
    } on MissingPluginException {
      // A central interna continua sendo atualizada ao abrir o app.
    }
  }

  Future<void> markAllRead() => _serialized(() async {
    final records = await loadNotifications();
    await _write(records.map((item) => item.copyWith(read: true)).toList());
  });

  Future<void> clear() => _serialized(() async => _write([]));

  Future<void> _write(List<AppNotification> records) async {
    final file = await _dataFile();
    await file.writeAsString(
      jsonEncode(records.map((item) => item.toJson()).toList()),
      flush: true,
    );
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    this.updates = true,
    this.maintenance = true,
    this.fuelLow = true,
    this.overfill = true,
  });

  final bool updates;
  final bool maintenance;
  final bool fuelLow;
  final bool overfill;

  bool get allEnabled => updates && maintenance && fuelLow && overfill;
  bool get anyEnabled => updates || maintenance || fuelLow || overfill;

  bool allows(String category) => switch (category) {
    'maintenance' => maintenance,
    'fuelLow' => fuelLow,
    'overfill' => overfill,
    _ => updates,
  };

  NotificationPreferences copyWith({
    bool? updates,
    bool? maintenance,
    bool? fuelLow,
    bool? overfill,
  }) => NotificationPreferences(
    updates: updates ?? this.updates,
    maintenance: maintenance ?? this.maintenance,
    fuelLow: fuelLow ?? this.fuelLow,
    overfill: overfill ?? this.overfill,
  );

  Map<String, dynamic> toJson() => {
    'updates': updates,
    'maintenance': maintenance,
    'fuelLow': fuelLow,
    'overfill': overfill,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        updates: json['updates'] as bool? ?? true,
        maintenance: json['maintenance'] as bool? ?? true,
        fuelLow: json['fuelLow'] as bool? ?? true,
        overfill: json['overfill'] as bool? ?? true,
      );
}
