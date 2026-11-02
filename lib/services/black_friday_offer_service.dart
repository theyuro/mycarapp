import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Fase da campanha de Black Friday, cada uma com seu próprio limite de
/// exibições por usuário (ver [BlackFridayOfferService.canShow]).
enum BlackFridayPhase { first, second, last }

/// Controla a janela e a frequência do banner de Black Friday (60% no 1º ano
/// do anual, oferta real da Play — ver `AccessService.blackFridayOption`):
/// - a campanha acaba em [campaignEnd] (30/11 às 23h de Brasília), prazo que
///   também vale na Play Console para a oferta `blackfriday26`;
/// - cada fase ([BlackFridayPhase]) tem um limite próprio de exibições por
///   conta, para não repetir o banner à exaustão;
/// - quem já é Premium nunca vê (decidido pelo widget, via AccessService).
class BlackFridayOfferService {
  BlackFridayOfferService._();
  static final BlackFridayOfferService instance = BlackFridayOfferService._();

  /// Fim da 1ª fase: 15/11/2026 às 23h59 de Brasília (UTC-3).
  static final DateTime phase1End = DateTime.utc(2026, 11, 16, 2, 59, 59);

  /// Fim da 2ª fase: 29/11/2026 às 23h59 de Brasília.
  static final DateTime phase2End = DateTime.utc(2026, 11, 30, 2, 59, 59);

  /// Fim da campanha (3ª fase, "última chance"): 30/11/2026 às 23h de
  /// Brasília — mesmo horário da oferta na Play Console.
  static final DateTime campaignEnd = DateTime.utc(2026, 12, 1, 2, 0, 0);

  static const _maxPerPhase = <BlackFridayPhase, int>{
    BlackFridayPhase.first: 2,
    BlackFridayPhase.second: 2,
    BlackFridayPhase.last: 2,
  };

  final Map<BlackFridayPhase, int> _shownCount = {};
  Future<void>? _loaded;

  /// Fase atual da campanha, ou `null` se ainda não começou ou já terminou.
  BlackFridayPhase? get currentPhase {
    final now = DateTime.now().toUtc();
    if (now.isAfter(campaignEnd)) return null;
    if (now.isBefore(phase1End)) return BlackFridayPhase.first;
    if (now.isBefore(phase2End)) return BlackFridayPhase.second;
    return BlackFridayPhase.last;
  }

  /// Tempo restante até o fim da campanha (zero se já terminou).
  Duration get timeUntilEnd {
    final remaining = campaignEnd.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Se o banner pode aparecer agora: dentro da campanha e sem ter
  /// esgotado o limite de exibições da fase atual.
  Future<bool> canShow() async {
    final phase = currentPhase;
    if (phase == null) return false;
    await (_loaded ??= _loadState());
    final shown = _shownCount[phase] ?? 0;
    return shown < _maxPerPhase[phase]!;
  }

  /// Grava que o banner acabou de ser exibido na fase atual.
  Future<void> markShown() async {
    final phase = currentPhase;
    if (phase == null) return;
    await (_loaded ??= _loadState());
    _shownCount[phase] = (_shownCount[phase] ?? 0) + 1;
    await _saveState();
  }

  Future<File> _stateFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}black_friday_offer.json',
    );
  }

  Future<void> _loadState() async {
    try {
      final file = await _stateFile();
      if (!await file.exists()) return;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      json.forEach((key, value) {
        final phase = _phaseFromName(key);
        if (phase != null) _shownCount[phase] = value as int;
      });
    } on Object {
      debugPrint('Estado do banner Black Friday corrompido; reiniciando.');
    }
  }

  Future<void> _saveState() async {
    try {
      final file = await _stateFile();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode(
          _shownCount.map((key, value) => MapEntry(key.name, value)),
        ),
        flush: true,
      );
      await temporary.rename(file.path);
    } on Object catch (error) {
      debugPrint('Não foi possível salvar o estado do banner Black Friday: $error');
    }
  }

  BlackFridayPhase? _phaseFromName(String name) {
    for (final phase in BlackFridayPhase.values) {
      if (phase.name == name) return phase;
    }
    return null;
  }
}
