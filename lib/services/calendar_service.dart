import 'package:flutter/services.dart';
import '../l10n/l10n.dart';

class CalendarService {
  static const _channel = MethodChannel('mycarapp/calendar');

  Future<void> addAllDayMaintenance({
    required DateTime date,
    required String service,
    required String category,
  }) => _channel.invokeMethod<void>('addAllDayEvent', {
    'title': tr.calendarEventTitle,
    'description': '$service • $category',
    'date': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
  });
}
