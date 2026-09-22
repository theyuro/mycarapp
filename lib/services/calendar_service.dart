import 'package:flutter/services.dart';

class CalendarService {
  static const _channel = MethodChannel('mycarapp/calendar');

  Future<void> addAllDayMaintenance({
    required DateTime date,
    required String service,
    required String category,
  }) => _channel.invokeMethod<void>('addAllDayEvent', {
    'title': 'MyCarApp Manutenção',
    'description': '$service • $category',
    'date': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
  });
}
