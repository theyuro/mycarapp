import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';

import 'access_service.dart';
import 'ads_config.dart';

/// Telas com banner no rodapé. Cada uma usa o próprio bloco de anúncio no
/// AdMob, para acompanhar a receita por tela.
enum BannerPlacement { home, fuelingHistory, maintenance, expenses, vehicles }

/// Resultado de uma tentativa de assistir ao vídeo premiado.
enum RewardedResult {
  /// Assistiu até o fim e ganhou o período sem anúncios em tela cheia.
  earned,

  /// Fechou o vídeo antes do fim: nada é concedido.
  notEarned,

  /// O vídeo não estava carregado ou falhou ao abrir.
  unavailable,
}

class AdsService extends ChangeNotifier {
  AdsService._();

  static final AdsService instance = AdsService._();

  static const _androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';
  // Bloco de banner de produção (Android). Usado só em release: em debug
  // seguem os IDs de teste, para não gerar tráfego inválido no AdMob.
  // É o bloco original do app, mantido no banner da tela inicial.
  static const _androidProductionBannerId =
      'ca-app-pub-3009025921589541/3136303292';
  // Um bloco de banner por tela (Android, produção).
  static const _androidProductionFuelingHistoryBannerId =
      'ca-app-pub-3009025921589541/2338715615';
  static const _androidProductionMaintenanceBannerId =
      'ca-app-pub-3009025921589541/3846404250';
  static const _androidProductionExpensesBannerId =
      'ca-app-pub-3009025921589541/6987572918';
  static const _androidProductionVehiclesBannerId =
      'ca-app-pub-3009025921589541/6332791788';
  static const _configuredBannerId = String.fromEnvironment(
    'ADMOB_BANNER_AD_UNIT_ID',
  );

  static const _androidTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _iosTestInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  // Bloco intersticial de produção (Android), exibido entre atividades.
  static const _androidProductionInterstitialId =
      'ca-app-pub-3009025921589541/5946207574';

  static const _androidTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const _iosTestRewardedId = 'ca-app-pub-3940256099942544/1712485313';
  // Vídeo premiado de produção (Android): dá horas sem anúncios em tela cheia.
  static const _androidProductionRewardedId =
      'ca-app-pub-3009025921589541/9982146770';

  static const _androidTestNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const _iosTestNativeId = 'ca-app-pub-3940256099942544/3986624511';
  // Anúncio nativo de produção (Android), exibido entre os itens das listas.
  static const _androidProductionNativeId =
      'ca-app-pub-3009025921589541/2393546777';

  /// Teto do período sem anúncios em tela cheia, mesmo somando vários vídeos.
  static const _maxAdFree = Duration(hours: 9);

  bool _initialized = false;
  InterstitialAd? _interstitial;
  DateTime? _interstitialLoadedAt;
  // O AdMob invalida um intersticial carregado após 1 hora; acima disto ele
  // é descartado e recarregado em vez de falhar na exibição.
  static const _interstitialMaxAge = Duration(minutes: 55);
  bool _loadingInterstitial = false;
  // O vídeo premiado segue a mesma regra de validade do intersticial.
  RewardedAd? _rewarded;
  DateTime? _rewardedLoadedAt;
  bool _loadingRewarded = false;
  bool _showingRewarded = false;
  // Persistido em disco: o app é de pouco uso, então o contador precisa
  // sobreviver ao fechamento para o intersticial chegar a aparecer.
  final _AdsState _state = _AdsState();
  Future<void>? _stateLoaded;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;

  /// Chamado quando o usuário fecha um intersticial; o app usa para mostrar
  /// o convite para assinar o Premium.
  VoidCallback? onInterstitialDismissed;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool get canRequestAds =>
      supported &&
      _canRequestAds &&
      (!kReleaseMode ||
          _configuredBannerId.isNotEmpty ||
          defaultTargetPlatform == TargetPlatform.android);
  bool get privacyOptionsRequired => supported && _privacyOptionsRequired;

  /// Bloco de banner da [placement]. O override `ADMOB_BANNER_AD_UNIT_ID`
  /// tem prioridade; em debug é sempre o ID de teste.
  String bannerAdUnitId(BannerPlacement placement) {
    if (_configuredBannerId.isNotEmpty) return _configuredBannerId;
    if (kReleaseMode && defaultTargetPlatform == TargetPlatform.android) {
      return switch (placement) {
        BannerPlacement.home => _androidProductionBannerId,
        BannerPlacement.fuelingHistory =>
          _androidProductionFuelingHistoryBannerId,
        BannerPlacement.maintenance => _androidProductionMaintenanceBannerId,
        BannerPlacement.expenses => _androidProductionExpensesBannerId,
        BannerPlacement.vehicles => _androidProductionVehiclesBannerId,
      };
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestBannerId
        : _androidTestBannerId;
  }

  String get interstitialAdUnitId {
    if (kReleaseMode && defaultTargetPlatform == TargetPlatform.android) {
      return _androidProductionInterstitialId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestInterstitialId
        : _androidTestInterstitialId;
  }

  String get rewardedAdUnitId {
    if (kReleaseMode && defaultTargetPlatform == TargetPlatform.android) {
      return _androidProductionRewardedId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestRewardedId
        : _androidTestRewardedId;
  }

  String get nativeAdUnitId {
    if (kReleaseMode && defaultTargetPlatform == TargetPlatform.android) {
      return _androidProductionNativeId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestNativeId
        : _androidTestNativeId;
  }

  bool get _shouldShowAds => canRequestAds && AccessService.instance.showsAds;

  bool get _shouldLoadRewarded =>
      _shouldShowAds && AdsConfig.instance.rewardedEnabled;

  /// Período sem anúncios em tela cheia ganho no vídeo premiado. Não esconde
  /// banners nem nativos.
  bool get adFreeActive {
    final until = _state.adFreeUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// Quanto falta do período sem anúncios em tela cheia, ou nulo se não há.
  Duration? get adFreeRemaining {
    final until = _state.adFreeUntil;
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// O período sem anúncios em tela cheia já está no teto: outro vídeo não
  /// somaria mais tempo.
  bool get adFreeAtLimit {
    final remaining = adFreeRemaining;
    return remaining != null &&
        remaining >= _maxAdFree - const Duration(minutes: 1);
  }

  /// Há um vídeo premiado carregado e ainda válido para exibir.
  bool get rewardedReady {
    final loadedAt = _rewardedLoadedAt;
    return _rewarded != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) <= _interstitialMaxAge;
  }

  /// Garante que o estado persistido (contadores, carência, período sem
  /// anúncios) foi lido do disco.
  Future<void> ensureStateLoaded() => _stateLoaded ??= _loadState();

  /// Registra uma atividade principal concluída e, quando as regras de
  /// frequência permitem, exibe o intersticial.
  void registerMainActivity() => unawaited(_registerMainActivity());

  Future<void> _registerMainActivity() async {
    if (!_shouldShowAds) return;
    await ensureStateLoaded();
    _state.activitiesSinceInterstitial++;
    unawaited(_saveState());
    final blockedBy = _interstitialBlockedBy();
    if (blockedBy != null) {
      debugPrint('Anúncios: intersticial adiado ($blockedBy).');
      _loadInterstitial();
      return;
    }
    final loadedAt = _interstitialLoadedAt;
    if (_interstitial != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) > _interstitialMaxAge) {
      _interstitial!.dispose();
      _interstitial = null;
    }
    final ad = _interstitial;
    if (ad == null) {
      // Ainda não carregou: tenta de novo na próxima atividade.
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _recordInterstitialShown(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        onInterstitialDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        reportAdIssue(
          'interstitial_show',
          'code=${error.code} domain=${error.domain} ${error.message}',
        );
        ad.dispose();
        _loadInterstitial();
      },
    );
    unawaited(ad.show());
  }

  /// Retorna o motivo que impede o intersticial agora, ou nulo se todas as
  /// regras de frequência foram cumpridas.
  String? _interstitialBlockedBy() {
    final config = AdsConfig.instance;
    final now = DateTime.now();
    _state.rollDay(now);
    if (_state.activitiesSinceInterstitial <
        config.interstitialActivitiesPerShow) {
      return 'contador ${_state.activitiesSinceInterstitial}/'
          '${config.interstitialActivitiesPerShow}';
    }
    final last = _state.lastInterstitialAt;
    if (last != null && now.difference(last) < config.interstitialMinInterval) {
      return 'intervalo mínimo';
    }
    if (_state.interstitialsToday >= config.interstitialMaxPerDay) {
      return 'limite diário ${_state.interstitialsToday}/'
          '${config.interstitialMaxPerDay}';
    }
    final firstOpen = _state.firstOpenAt ?? now;
    if (now.difference(firstOpen).inDays < config.interstitialGraceDays) {
      return 'carência de ${config.interstitialGraceDays} dias';
    }
    if (adFreeActive) return 'período sem anúncios em tela cheia';
    return null;
  }

  void _recordInterstitialShown() {
    final now = DateTime.now();
    _state.rollDay(now);
    _state.activitiesSinceInterstitial = 0;
    _state.lastInterstitialAt = now;
    _state.interstitialsToday++;
    unawaited(_saveState());
    _logEvent('ad_interstitial_shown');
  }

  /// Se o convite Premium após o anúncio pode aparecer agora (ligado no
  /// Remote Config e fora do intervalo desde o último convite).
  Future<bool> premiumAfterAdDue() async {
    final config = AdsConfig.instance;
    if (!config.premiumAfterAdEnabled) return false;
    await ensureStateLoaded();
    final last = _state.lastPremiumAfterAdAt;
    return last == null ||
        DateTime.now().difference(last) >= config.premiumAfterAdInterval;
  }

  /// Grava que o convite Premium após o anúncio acabou de ser exibido.
  Future<void> markPremiumAfterAdShown() async {
    await ensureStateLoaded();
    _state.lastPremiumAfterAdAt = DateTime.now();
    await _saveState();
  }

  /// Exibe o vídeo premiado. A recompensa só é concedida em
  /// `onUserEarnedReward`; fechar antes do fim não dá nada.
  Future<RewardedResult> showRewarded() async {
    if (_showingRewarded) return RewardedResult.unavailable;
    if (!rewardedReady) {
      _rewarded?.dispose();
      _rewarded = null;
      loadRewarded();
      return RewardedResult.unavailable;
    }
    await ensureStateLoaded();
    final ad = _rewarded!;
    _rewarded = null;
    _showingRewarded = true;
    var earned = false;
    final completion = Completer<RewardedResult>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingRewarded = false;
        loadRewarded();
        if (!completion.isCompleted) {
          completion.complete(
            earned ? RewardedResult.earned : RewardedResult.notEarned,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        reportAdIssue(
          'rewarded_show',
          'code=${error.code} domain=${error.domain} ${error.message}',
        );
        ad.dispose();
        _showingRewarded = false;
        loadRewarded();
        if (!completion.isCompleted) {
          completion.complete(RewardedResult.unavailable);
        }
      },
    );
    unawaited(
      ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
          _grantAdFree();
        },
      ),
    );
    return completion.future;
  }

  void _grantAdFree() {
    final now = DateTime.now();
    final hours = Duration(hours: AdsConfig.instance.rewardedAdFreeHours);
    // Com um período ainda ativo, soma ao tempo restante, até o teto.
    final current = _state.adFreeUntil;
    final start = current != null && current.isAfter(now) ? current : now;
    var until = start.add(hours);
    final limit = now.add(_maxAdFree);
    if (until.isAfter(limit)) until = limit;
    _state.adFreeUntil = until;
    unawaited(_saveState());
    notifyListeners();
    _logEvent('ad_rewarded_earned');
  }

  /// Carrega o vídeo premiado, se ainda não houver um válido.
  void loadRewarded() {
    if (!_shouldLoadRewarded || _loadingRewarded || _showingRewarded) return;
    if (_rewarded != null) {
      if (rewardedReady) return;
      // Expirou: descarta e busca outro.
      _rewarded!.dispose();
      _rewarded = null;
    }
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded = ad;
          _rewardedLoadedAt = DateTime.now();
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          reportAdIssue(
            'rewarded_load',
            'code=${error.code} domain=${error.domain} ${error.message}',
          );
        },
      ),
    );
  }

  void _logEvent(String name) {
    try {
      unawaited(FirebaseAnalytics.instance.logEvent(name: name));
    } on Object {
      // Firebase indisponível: o evento é só estatística.
    }
  }

  Future<Directory> _stateDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _stateFile() async {
    final directory = await _stateDirectory();
    return File('${directory.path}${Platform.pathSeparator}ads_state.json');
  }

  /// Arquivo antigo, só com o contador de atividades (até a v1.3.4).
  Future<File> _legacyCounterFile() async {
    final directory = await _stateDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}interstitial_counter.txt',
    );
  }

  Future<void> _loadState() async {
    var changed = false;
    try {
      final file = await _stateFile();
      if (await file.exists()) {
        _state.readJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
      }
    } on Object catch (error) {
      debugPrint('Estado dos anúncios corrompido; reiniciando: $error');
    }
    File? legacy;
    try {
      final candidate = await _legacyCounterFile();
      if (await candidate.exists()) {
        legacy = candidate;
        _state.activitiesSinceInterstitial =
            int.tryParse((await candidate.readAsString()).trim()) ?? 0;
        // Quem já tinha o contador antigo usa o app há tempo: a carência de
        // dias sem intersticial não vale para essa pessoa.
        _state.firstOpenAt ??= DateTime.now().subtract(
          const Duration(days: 365),
        );
        changed = true;
      }
    } on Object catch (error) {
      debugPrint('Não foi possível ler o contador de anúncios: $error');
    }
    if (_state.firstOpenAt == null) {
      // Usuário novo: a carência começa a contar agora.
      _state.firstOpenAt = DateTime.now();
      changed = true;
    }
    if (!changed) return;
    final saved = await _saveState();
    // Só apaga o arquivo antigo depois que o novo foi gravado, para não
    // perder a migração se o app fechar no meio.
    if (saved && legacy != null) {
      try {
        await legacy.delete();
      } on Object catch (error) {
        debugPrint('Não foi possível apagar o contador antigo: $error');
      }
    }
  }

  Future<bool> _saveState() async {
    try {
      final file = await _stateFile();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(_state.toJson()), flush: true);
      await temporary.rename(file.path);
      return true;
    } on Object catch (error) {
      debugPrint('Não foi possível salvar o estado dos anúncios: $error');
      return false;
    }
  }

  void _loadInterstitial() {
    if (!_shouldShowAds || _interstitial != null || _loadingInterstitial) {
      return;
    }
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
          _interstitialLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          reportAdIssue(
            'interstitial_load',
            'code=${error.code} domain=${error.domain} ${error.message}',
          );
        },
      ),
    );
  }

  Future<void> initialize() async {
    if (!supported || _initialized) return;
    _initialized = true;
    // Lê o estado logo na abertura, para gravar a primeira abertura (base da
    // carência) e já saber se há período sem anúncios ativo.
    unawaited(ensureStateLoaded().then((_) => notifyListeners()));

    await MobileAds.instance.initialize();
    final completion = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((error) async {
          if (error != null) {
            reportAdIssue(
              'consent_form',
              'code=${error.errorCode} ${error.message}',
            );
          }
          await _refreshConsentState();
          if (!completion.isCompleted) completion.complete();
        });
      },
      (error) async {
        reportAdIssue(
          'consent_update',
          'code=${error.errorCode} ${error.message}',
        );
        await _refreshConsentState();
        if (!completion.isCompleted) completion.complete();
      },
    );

    await completion.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () async {
        reportAdIssue('consent_timeout', 'sem resposta do UMP em 12s');
        await _refreshConsentState();
      },
    );
    if (!_canRequestAds) {
      reportAdIssue('consent_blocked', 'canRequestAds=false após o UMP');
    }
  }

  /// Registra no Crashlytics (não fatal) uma falha do fluxo de anúncios, para
  /// diagnosticar em produção por que um anúncio não foi pedido ou exibido.
  void reportAdIssue(String stage, String details) {
    debugPrint('Anúncios [$stage]: $details');
    try {
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          'AdMob $stage: $details',
          null,
          reason: 'ads_$stage',
        ),
      );
    } on Object {
      // Firebase indisponível: o log acima já basta.
    }
  }

  Future<void> _refreshConsentState() async {
    final canRequest = await ConsentInformation.instance.canRequestAds();
    final privacyStatus = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    final privacyRequired =
        privacyStatus == PrivacyOptionsRequirementStatus.required;
    if (_canRequestAds == canRequest &&
        _privacyOptionsRequired == privacyRequired) {
      return;
    }
    _canRequestAds = canRequest;
    _privacyOptionsRequired = privacyRequired;
    try {
      unawaited(
        FirebaseCrashlytics.instance.setCustomKey(
          'ads_can_request',
          canRequest,
        ),
      );
    } on Object {
      // Firebase indisponível.
    }
    notifyListeners();
    _loadInterstitial();
    loadRewarded();
  }

  Future<String?> showPrivacyOptions() async {
    final completion = Completer<String?>();
    ConsentForm.showPrivacyOptionsForm((error) async {
      await _refreshConsentState();
      if (!completion.isCompleted) completion.complete(error?.message);
    });
    return completion.future;
  }
}

/// Estado dos anúncios persistido em `ads_state.json`.
class _AdsState {
  int activitiesSinceInterstitial = 0;
  DateTime? lastInterstitialAt;
  int interstitialsToday = 0;
  // Data local (aaaa-mm-dd) a que [interstitialsToday] se refere.
  String? interstitialsDate;
  DateTime? firstOpenAt;
  DateTime? adFreeUntil;
  DateTime? lastPremiumAfterAdAt;

  /// Zera o contador diário quando a data local muda.
  void rollDay(DateTime now) {
    final today = _dayKey(now);
    if (interstitialsDate == today) return;
    interstitialsDate = today;
    interstitialsToday = 0;
  }

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  void readJson(Map<String, dynamic> json) {
    activitiesSinceInterstitial =
        (json['activitiesSinceInterstitial'] as num?)?.toInt() ?? 0;
    lastInterstitialAt = _date(json['lastInterstitialAt']);
    interstitialsToday = (json['interstitialsToday'] as num?)?.toInt() ?? 0;
    interstitialsDate = json['interstitialsDate'] as String?;
    firstOpenAt = _date(json['firstOpenAt']);
    adFreeUntil = _date(json['adFreeUntil']);
    lastPremiumAfterAdAt = _date(json['lastPremiumAfterAdAt']);
  }

  Map<String, dynamic> toJson() => {
    'activitiesSinceInterstitial': activitiesSinceInterstitial,
    'lastInterstitialAt': lastInterstitialAt?.toIso8601String(),
    'interstitialsToday': interstitialsToday,
    'interstitialsDate': interstitialsDate,
    'firstOpenAt': firstOpenAt?.toIso8601String(),
    'adFreeUntil': adFreeUntil?.toIso8601String(),
    'lastPremiumAfterAdAt': lastPremiumAfterAdAt?.toIso8601String(),
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
