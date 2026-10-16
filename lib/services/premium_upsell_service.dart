import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Telas onde o [PremiumUpsellBanner] aparece. Cada uma tem a própria
/// mensagem e o próprio controle de dispensa.
enum UpsellPlacement {
  home,
  vehicles,
  establishments,
  fuelingHistory,
  maintenance,
  expenses,
}

/// Controla quando o banner de assinatura pode aparecer:
/// - dispensar esconde aquele banner por [snoozeDuration];
/// - cada dispensa seguida aumenta o intervalo (3, 6, 9... dias, até 30),
///   para insistir menos com quem não tem interesse;
/// - quem é Premium nunca vê (decidido pelo widget, via AccessService).
class PremiumUpsellService {
  PremiumUpsellService._();
  static final PremiumUpsellService instance = PremiumUpsellService._();

  static const snoozeDuration = Duration(days: 3);
  static const _maxSnooze = Duration(days: 30);

  final Map<UpsellPlacement, DateTime> _hiddenUntil = {};
  final Map<UpsellPlacement, int> _dismissCount = {};
  Future<void>? _loaded;

  Future<bool> canShow(UpsellPlacement placement) async {
    await (_loaded ??= _loadState());
    final until = _hiddenUntil[placement];
    return until == null || DateTime.now().isAfter(until);
  }

  Future<void> dismiss(UpsellPlacement placement) async {
    await (_loaded ??= _loadState());
    final count = (_dismissCount[placement] ?? 0) + 1;
    _dismissCount[placement] = count;
    var snooze = snoozeDuration * count;
    if (snooze > _maxSnooze) snooze = _maxSnooze;
    _hiddenUntil[placement] = DateTime.now().add(snooze);
    await _saveState();
  }

  Future<File> _stateFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}premium_upsell.json',
    );
  }

  Future<void> _loadState() async {
    try {
      final file = await _stateFile();
      if (!await file.exists()) return;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final hiddenUntil = json['hiddenUntil'] as Map<String, dynamic>?;
      final dismissCount = json['dismissCount'] as Map<String, dynamic>?;
      hiddenUntil?.forEach((key, value) {
        final placement = _placementFromName(key);
        if (placement != null) {
          _hiddenUntil[placement] = DateTime.parse(value as String);
        }
      });
      dismissCount?.forEach((key, value) {
        final placement = _placementFromName(key);
        if (placement != null) _dismissCount[placement] = value as int;
      });
    } on Object {
      debugPrint('Estado do banner Premium corrompido; reiniciando.');
    }
  }

  Future<void> _saveState() async {
    try {
      final file = await _stateFile();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({
          'hiddenUntil': _hiddenUntil.map(
            (key, value) => MapEntry(key.name, value.toIso8601String()),
          ),
          'dismissCount': _dismissCount.map(
            (key, value) => MapEntry(key.name, value),
          ),
        }),
        flush: true,
      );
      await temporary.rename(file.path);
    } on Object catch (error) {
      debugPrint('Não foi possível salvar o estado do banner Premium: $error');
    }
  }

  UpsellPlacement? _placementFromName(String name) {
    for (final placement in UpsellPlacement.values) {
      if (placement.name == name) return placement;
    }
    return null;
  }
}
