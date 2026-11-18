import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/vehicle.dart';
import 'access_service.dart';
import 'ads_config.dart';
import 'ads_service.dart';
import 'analytics_service.dart';

/// Regras do plano gratuito (gratuito × Premium). `AccessService.premiumUnlocked`
/// libera todos os limites abaixo; sem Premium, alguns recursos têm um limite
/// fixo por mês, outros são liberados assistindo a um vídeo premiado por uso,
/// e os demais são só Premium.
///
/// Os números (`maxVehicles`, `fuelingsPerMonth`, `stationUnlockDays`) vêm do
/// Remote Config (ver AdsConfig), com os mesmos padrões aqui documentados.
class FreePlanService {
  FreePlanService._();

  static final FreePlanService instance = FreePlanService._();

  bool get _premiumUnlocked => AccessService.instance.premiumUnlocked;

  /// Veículos cadastráveis no plano gratuito (padrão 1).
  int get maxVehicles => AdsConfig.instance.freeMaxVehicles;

  /// Abastecimentos gratuitos por mês (padrão 3); acima disso, cada novo
  /// abastecimento é liberado por vídeo premiado.
  int get fuelingsPerMonth => AdsConfig.instance.freeFuelingsPerMonth;

  /// Intervalo mínimo, em dias, entre duas liberações do melhor posto no
  /// gratuito (padrão 30). Antes era o "pior posto após vídeo", a cada 7 dias;
  /// agora é o melhor posto, sem vídeo.
  int get stationUnlockDays => AdsConfig.instance.freeStationUnlockDays;

  // ---------------------------------------------------------------------
  // Veículos
  // ---------------------------------------------------------------------

  /// Se é possível cadastrar mais um veículo com [currentVehicleCount] já
  /// cadastrados.
  bool canAddVehicle(int currentVehicleCount) => _allowedOrBlocked(
    _premiumUnlocked || currentVehicleCount < maxVehicles,
    'vehicles',
  );

  /// Se o veículo [vehicleId] pode receber novos abastecimentos, manutenções
  /// ou despesas no gratuito. Usuários com mais de um veículo cadastrado
  /// antes deste limite existir (ou que ainda tenham mais de [maxVehicles])
  /// mantêm todos os veículos visíveis, mas só o cadastrado primeiro
  /// continua aceitando lançamentos novos; os demais ficam só para consulta.
  bool canRegisterForVehicle(List<Vehicle> vehicles, String vehicleId) {
    if (_premiumUnlocked || vehicles.length <= 1) return true;
    final sorted = [...vehicles]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _allowedOrBlocked(sorted.first.id == vehicleId, 'vehicles');
  }

  // ---------------------------------------------------------------------
  // Abastecimentos
  // ---------------------------------------------------------------------

  /// Se um novo abastecimento ainda está dentro da cota gratuita do mês,
  /// dado [fuelingsThisMonth] já registrados no mês corrente.
  bool fuelingWithinFreeQuota(int fuelingsThisMonth) => _allowedOrBlocked(
    _premiumUnlocked || fuelingsThisMonth < fuelingsPerMonth,
    'fuelings',
  );

  /// Conta quantas das [dates] (datas dos abastecimentos) caem no mês
  /// corrente, para alimentar [fuelingWithinFreeQuota]. A cota é por mês
  /// civil: zera no dia 1.
  int countInCurrentMonth(Iterable<DateTime> dates) {
    final now = DateTime.now();
    return dates
        .where((date) => date.year == now.year && date.month == now.month)
        .length;
  }

  /// Libera um abastecimento acima da cota gratuita assistindo ao vídeo
  /// premiado. Chamar só quando [fuelingWithinFreeQuota] for `false`.
  Future<bool> unlockFuelingWithRewarded() =>
      _unlockWithRewardedUnlessPremium('fuelings');

  // ---------------------------------------------------------------------
  // Manutenção e despesas: cada novo registro é liberado por vídeo premiado
  // (sem limite mensal, diferente dos abastecimentos).
  // ---------------------------------------------------------------------

  Future<bool> unlockMaintenanceWithRewarded() =>
      _unlockWithRewardedUnlessPremium('maintenance');

  Future<bool> unlockExpenseWithRewarded() =>
      _unlockWithRewardedUnlessPremium('expense');

  // ---------------------------------------------------------------------
  // Recursos só Premium.
  // ---------------------------------------------------------------------

  /// Leitura de nota fiscal por OCR: só Premium.
  bool get receiptScanAllowed =>
      _allowedOrBlocked(_premiumUnlocked, 'receipt_scan');

  /// Ranking completo de postos (todas as posições): só Premium. O melhor
  /// posto isolado tem regra própria, logo abaixo ([bestStationUnlocked]).
  bool get stationRankingAllowed =>
      _allowedOrBlocked(_premiumUnlocked, 'station_ranking');

  /// Relatórios por período personalizado: só Premium.
  bool get periodReportsAllowed =>
      _allowedOrBlocked(_premiumUnlocked, 'period_reports');

  /// Exportação em CSV/Excel: só Premium.
  bool get exportAllowed => _allowedOrBlocked(_premiumUnlocked, 'export');

  /// Backup automático em nuvem: só Premium (delega para AccessService, que
  /// já tem essa regra).
  bool get backupAllowed =>
      _allowedOrBlocked(AccessService.instance.cloudBackupEnabled, 'backup');

  // ---------------------------------------------------------------------
  // PDF: Premium, ou vídeo premiado a cada exportação.
  // ---------------------------------------------------------------------

  /// Se o PDF sai direto, sem o diálogo do vídeo (só Premium).
  bool get pdfAllowed => _allowedOrBlocked(_premiumUnlocked, 'pdf');

  Future<bool> unlockPdfExport() => _unlockWithRewardedUnlessPremium('pdf');

  // ---------------------------------------------------------------------
  // Melhor posto: o ranking completo é só Premium ([stationRankingAllowed]);
  // no gratuito, o melhor posto (sem vídeo) é liberado no máximo 1 vez a
  // cada [stationUnlockDays] e fica visível enquanto o app estiver aberto,
  // até o processo encerrar. Substitui o antigo "pior posto após vídeo".
  // ---------------------------------------------------------------------

  /// Lê do disco a data da última liberação do melhor posto. Chamar na
  /// abertura do app (ou antes de montar a tela de postos).
  Future<void> initialize() => _ensureStateLoaded();

  // Liberação da sessão atual: só em memória, para o melhor posto continuar
  // visível até o processo do app encerrar, mesmo depois de sair do relatório.
  bool _bestStationSessionUnlocked = false;

  /// Se o melhor posto pode ser exibido agora: Premium, ou liberado nesta
  /// sessão por [unlockBestStationIfDue].
  bool get bestStationUnlocked =>
      _premiumUnlocked || _bestStationSessionUnlocked;

  /// Chamada na abertura do relatório: se já passaram [stationUnlockDays]
  /// desde a última liberação (ou se nunca houve uma), grava a data de agora
  /// e marca a sessão como liberada. Devolve [bestStationUnlocked].
  Future<bool> unlockBestStationIfDue() async {
    if (bestStationUnlocked) return true;
    await _ensureStateLoaded();
    final last = _state.lastBestStationUnlockAt;
    if (last == null ||
        DateTime.now().difference(last).inDays >= stationUnlockDays) {
      _state.lastBestStationUnlockAt = DateTime.now();
      _bestStationSessionUnlocked = true;
      unawaited(_saveState());
    }
    return bestStationUnlocked;
  }

  /// Quando o melhor posto volta a ser liberado no gratuito (usado no aviso
  /// do card). `null` se nunca foi liberado ou se o estado ainda não foi lido.
  DateTime? get nextBestStationUnlockAt {
    final last = _state.lastBestStationUnlockAt;
    return last?.add(Duration(days: stationUnlockDays));
  }

  // ---------------------------------------------------------------------
  // Pré-carregamento do vídeo premiado: chamado ao abrir as telas que podem
  // pedir vídeo, para o anúncio já estar pronto quando o usuário salvar.
  // Estas consultas não registram premium_feature_blocked (o bloqueio ainda
  // não aconteceu; é só uma previsão).
  // ---------------------------------------------------------------------

  /// O próximo abastecimento vai precisar de vídeo, dado
  /// [fuelingsThisMonth] já registrados no mês.
  bool fuelingNeedsRewarded(int fuelingsThisMonth) =>
      !_premiumUnlocked && fuelingsThisMonth >= fuelingsPerMonth;

  /// Manutenção, despesa e PDF pedem vídeo a cada uso no gratuito.
  bool get perUseNeedsRewarded => !_premiumUnlocked;

  /// Carrega o vídeo premiado se [needed] e o usuário for gratuito.
  void preloadRewardedIf(bool needed) {
    if (needed && !_premiumUnlocked) AdsService.instance.loadRewarded();
  }

  // ---------------------------------------------------------------------
  // Infra comum
  // ---------------------------------------------------------------------

  Future<bool> _unlockWithRewardedUnlessPremium(String feature) async {
    if (_premiumUnlocked) return true;
    return AdsService.instance.unlockWithRewarded(feature: feature);
  }

  // Último premium_feature_blocked registrado por recurso. Algumas regras
  // (ranking de postos, veículo só para consulta) são consultadas a cada
  // rebuild da tela; o intervalo evita um evento por rebuild.
  final Map<String, DateTime> _lastBlockedLog = {};
  static const _blockedLogInterval = Duration(seconds: 30);

  /// Devolve [allowed] e, quando a regra nega, registra
  /// `premium_feature_blocked` com o [feature] (no máximo 1 vez a cada
  /// [_blockedLogInterval] por recurso).
  bool _allowedOrBlocked(bool allowed, String feature) {
    if (allowed) return true;
    final now = DateTime.now();
    final last = _lastBlockedLog[feature];
    if (last == null || now.difference(last) >= _blockedLogInterval) {
      _lastBlockedLog[feature] = now;
      AnalyticsService.event('premium_feature_blocked', {'feature': feature});
    }
    return false;
  }

  // Estado persistido localmente: só a data da última liberação do melhor
  // posto (a liberação da sessão fica em [_bestStationSessionUnlocked]).
  final _FreePlanState _state = _FreePlanState();
  Future<void>? _stateLoaded;

  Future<void> _ensureStateLoaded() => _stateLoaded ??= _loadState();

  Future<File> _stateFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}free_plan_state.json',
    );
  }

  Future<void> _loadState() async {
    try {
      final file = await _stateFile();
      if (!await file.exists()) return;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      // Chave nova (melhor posto); a antiga, do pior posto após vídeo, é
      // ignorada de propósito, porque a regra mudou.
      _state.lastBestStationUnlockAt = json['lastBestStationUnlockAt'] == null
          ? null
          : DateTime.tryParse(json['lastBestStationUnlockAt'] as String);
    } on Object catch (error) {
      debugPrint('Estado do plano gratuito corrompido; reiniciando: $error');
    }
  }

  Future<void> _saveState() async {
    try {
      final file = await _stateFile();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({
          'lastBestStationUnlockAt':
              _state.lastBestStationUnlockAt?.toIso8601String(),
        }),
        flush: true,
      );
      await temporary.rename(file.path);
    } on Object catch (error) {
      debugPrint('Não foi possível salvar o estado do plano gratuito: $error');
    }
  }
}

class _FreePlanState {
  DateTime? lastBestStationUnlockAt;
}
