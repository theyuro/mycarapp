import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'fueling_storage_service.dart';
import 'maintenance_storage_service.dart';

/// Os três tipos de banner da Seção 5.1 do guia de planejamento. O tipo
/// `upgrade` (limite do plano gratuito) já é coberto pelos cards de upsell
/// contextuais espalhados pelas telas Premium (relatórios, backup) — este
/// serviço cuida apenas de `rating` e `referral`, que fazem sentido como um
/// componente genérico reaproveitável.
enum RecommendationBannerType { rating, referral }

/// Controla quando o [RecommendationBanner] pode aparecer, seguindo as
/// regras de comportamento da Seção 5.2 do guia:
/// - nunca para usuário novo (mínimo 3 lançamentos ou 7 dias de uso);
/// - nunca dispensável e reaparecendo antes de 30 dias;
/// - no máximo 1 banner por sessão, nunca 2 tipos na mesma sessão;
/// - após 3 dispensas do mesmo tipo, para de exibir para sempre;
/// - uma ação primária (avaliar/indicar) também esconde o tipo para sempre.
class RecommendationBannerService {
  RecommendationBannerService._();
  static final RecommendationBannerService instance =
      RecommendationBannerService._();

  DateTime? _firstUsedAt;
  final Map<RecommendationBannerType, int> _dismissCount = {};
  final Map<RecommendationBannerType, DateTime> _lastDismissedAt = {};
  final Set<RecommendationBannerType> _permanentlyHidden = {};
  RecommendationBannerType? _shownThisSession;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadState();
    _firstUsedAt ??= DateTime.now();
    await _saveState();
  }

  Future<bool> _hasMinimumUsage() async {
    final started = _firstUsedAt;
    if (started != null && DateTime.now().difference(started).inDays >= 7) {
      return true;
    }
    try {
      final fuelings = await FuelingStorageService().loadFuelings();
      final maintenances = await MaintenanceStorageService().loadMaintenances();
      return (fuelings.length + maintenances.length) >= 3;
    } on Object {
      return false;
    }
  }

  /// Se o tipo pode ser exibido agora. Não decide sozinho o gate de "já é
  /// Premium" (upgrade) nem "já avaliou" — quem chama decide isso antes,
  /// já que depende de outros serviços (AccessService, etc.).
  Future<bool> canShow(RecommendationBannerType type) async {
    if (_shownThisSession != null) return false;
    if (_permanentlyHidden.contains(type)) return false;
    final dismissedAt = _lastDismissedAt[type];
    if (dismissedAt != null &&
        DateTime.now().difference(dismissedAt).inDays < 30) {
      return false;
    }
    return _hasMinimumUsage();
  }

  void markShown(RecommendationBannerType type) {
    _shownThisSession = type;
  }

  Future<void> dismiss(RecommendationBannerType type) async {
    final count = (_dismissCount[type] ?? 0) + 1;
    _dismissCount[type] = count;
    _lastDismissedAt[type] = DateTime.now();
    if (count >= 3) _permanentlyHidden.add(type);
    await _saveState();
  }

  /// Chamado após a ação primária (avaliar/indicar) ser realizada — o
  /// banner correspondente nunca mais aparece.
  Future<void> hidePermanently(RecommendationBannerType type) async {
    _permanentlyHidden.add(type);
    await _saveState();
  }

  Future<File> _stateFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}recommendation_banner.json',
    );
  }

  Future<void> _loadState() async {
    final file = await _stateFile();
    if (!await file.exists()) return;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _firstUsedAt = json['firstUsedAt'] == null
          ? null
          : DateTime.parse(json['firstUsedAt'] as String);
      final dismissCount = json['dismissCount'] as Map<String, dynamic>?;
      final lastDismissedAt = json['lastDismissedAt'] as Map<String, dynamic>?;
      final permanentlyHidden = json['permanentlyHidden'] as List<dynamic>?;
      dismissCount?.forEach((key, value) {
        final type = _typeFromName(key);
        if (type != null) _dismissCount[type] = value as int;
      });
      lastDismissedAt?.forEach((key, value) {
        final type = _typeFromName(key);
        if (type != null) {
          _lastDismissedAt[type] = DateTime.parse(value as String);
        }
      });
      for (final name in permanentlyHidden ?? const []) {
        final type = _typeFromName(name as String);
        if (type != null) _permanentlyHidden.add(type);
      }
    } on Object {
      debugPrint('Estado do banner de recomendação corrompido; reiniciando.');
    }
  }

  Future<void> _saveState() async {
    final file = await _stateFile();
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temporary.writeAsString(
      jsonEncode({
        'firstUsedAt': _firstUsedAt?.toIso8601String(),
        'dismissCount': _dismissCount.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'lastDismissedAt': _lastDismissedAt.map(
          (key, value) => MapEntry(key.name, value.toIso8601String()),
        ),
        'permanentlyHidden': _permanentlyHidden
            .map((type) => type.name)
            .toList(),
      }),
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

  RecommendationBannerType? _typeFromName(String name) {
    for (final type in RecommendationBannerType.values) {
      if (type.name == name) return type;
    }
    return null;
  }
}
