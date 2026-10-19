import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';

import 'access_service.dart';
import 'ads_config.dart';
import 'analytics_service.dart';
import 'authentication_service.dart';
import 'fueling_storage_service.dart';
import 'vehicle_storage_service.dart';

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

  static const _androidTestAppOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const _iosTestAppOpenId = 'ca-app-pub-3940256099942544/5575463023';
  // Anúncio de abertura de produção (Android). A política do AdMob não
  // permite intersticial na abertura do app, só este formato.
  static const _androidProductionAppOpenId =
      'ca-app-pub-3009025921589541/8264833867';

  /// Teto do período sem anúncios em tela cheia, mesmo somando vários vídeos.
  static const _maxAdFree = Duration(hours: 9);

  bool _initialized = false;
  InterstitialAd? _interstitial;
  DateTime? _interstitialLoadedAt;
  // O AdMob invalida um intersticial carregado após 1 hora; acima disto ele
  // é descartado e recarregado em vez de falhar na exibição.
  static const _interstitialMaxAge = Duration(minutes: 55);
  // Ao salvar com o intersticial ainda carregando, espera no máximo isto
  // antes de desistir; mais que isso o anúncio pareceria fora de contexto.
  static const _interstitialShowWait = Duration(seconds: 3);
  bool _loadingInterstitial = false;
  Completer<void>? _interstitialLoad;
  // Anúncio de abertura: só para quem saiu do app devendo um anúncio (salvou
  // um registro e o intersticial não chegou a aparecer).
  AppOpenAd? _appOpen;
  DateTime? _appOpenLoadedAt;
  bool _loadingAppOpen = false;
  // O AdMob invalida um anúncio de abertura carregado após 4 horas.
  static const _appOpenMaxAge = Duration(hours: 3, minutes: 55);
  // Carregado depois disto da abertura, não é exibido (pareceria fora de
  // contexto, no meio do uso): fica guardado para a próxima abertura.
  static const _appOpenShowWindow = Duration(seconds: 8);
  // Voltar ao app depois de menos que isto (câmera, login, compra) não conta
  // como nova abertura.
  static const _appOpenMinBackground = Duration(minutes: 2);
  DateTime? _openedAt;
  DateTime? _hiddenAt;
  // Evita um anúncio de abertura logo ao voltar de outro anúncio em tela
  // cheia (a tela do anúncio também tira o app do primeiro plano).
  bool _fullScreenShowing = false;

  /// Se há um anúncio em tela cheia aberto (usado pelo pedido automático de
  /// avaliação, para não abrir por cima do anúncio).
  bool get fullScreenShowing => _fullScreenShowing;
  final _random = math.Random();
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
  // Fica verdadeiro quando a primeira consulta ao UMP termina (com sucesso,
  // erro ou tempo esgotado); antes disso o rodapé fica vazio em vez de
  // mostrar o anúncio próprio por alguns segundos.
  bool _consentChecked = false;
  bool _requestingConsent = false;
  // Fica verdadeiro (só em memória) quando o usuário já salvou mais
  // abastecimentos que AdsConfig.interstitialGraceRecords; daí em diante a
  // carência não é mais consultada no disco.
  bool _graceOver = false;

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

  /// O AdMob não vai entregar banner agora (sem consentimento, por exemplo
  /// ao abrir o app sem internet pela primeira vez): o rodapé mostra o
  /// anúncio próprio no lugar.
  bool get adsUnavailable => supported && _consentChecked && !canRequestAds;

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

  String get appOpenAdUnitId {
    if (kReleaseMode && defaultTargetPlatform == TargetPlatform.android) {
      return _androidProductionAppOpenId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestAppOpenId
        : _androidTestAppOpenId;
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

  /// Chamado na abertura do app (e ao voltar do segundo plano) e quando o
  /// usuário começa uma atividade principal. Carrega o intersticial só se ele
  /// puder ser exibido no próximo registro salvo: um anúncio carregado e
  /// nunca exibido conta como solicitação sem impressão no AdMob.
  ///
  /// Carregar já na abertura é necessário porque o uso típico é rápido
  /// (abre, registra o abastecimento e sai): carregando só ao digitar, o
  /// anúncio quase nunca ficava pronto antes de o usuário salvar.
  void prepareInterstitial() => unawaited(_prepareInterstitial());

  Future<void> _prepareInterstitial() async {
    if (!_shouldShowAds) return;
    await ensureStateLoaded();
    // Carência inicial: com poucos abastecimentos salvos, nem pré-carrega.
    // Conta o que está sendo registrado agora (+1), como pendingActivities.
    if (await _inGracePeriod(pendingFuelings: 1)) {
      debugPrint('Anúncios: intersticial não pré-carregado (carência).');
      return;
    }
    _discardExpiredInterstitial();
    if (_interstitial != null || _loadingInterstitial) return;
    final blockedBy = _interstitialBlockedBy(pendingActivities: 1);
    if (blockedBy != null) {
      debugPrint('Anúncios: intersticial não pré-carregado ($blockedBy).');
      return;
    }
    _loadInterstitial();
  }

  void _discardExpiredInterstitial() {
    final loadedAt = _interstitialLoadedAt;
    if (_interstitial != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) > _interstitialMaxAge) {
      _interstitial!.dispose();
      _interstitial = null;
    }
  }

  /// Registra uma atividade principal concluída e, quando as regras de
  /// frequência permitem, exibe o intersticial.
  void registerMainActivity() => unawaited(_registerMainActivity());

  Future<void> _registerMainActivity() async {
    if (!_shouldShowAds) return;
    await ensureStateLoaded();
    // Carência inicial: sem intersticial e sem deixar anúncio de abertura
    // pendente; o registro também não conta para o próximo intersticial.
    if (await _inGracePeriod()) {
      debugPrint('Anúncios: intersticial adiado (carência).');
      return;
    }
    _state.activitiesSinceInterstitial++;
    unawaited(_saveState());
    final blockedBy = _interstitialBlockedBy();
    if (blockedBy != null) {
      // Não carrega aqui: o próximo formulário aberto chama
      // [prepareInterstitial], que decide se vale a pena.
      debugPrint('Anúncios: intersticial adiado ($blockedBy).');
      return;
    }
    _discardExpiredInterstitial();
    final loading = _interstitialLoad;
    if (_interstitial == null && _loadingInterstitial && loading != null) {
      // Salvou antes de o anúncio terminar de carregar: espera um pouco.
      await loading.future.timeout(_interstitialShowWait, onTimeout: () {});
      // Saiu do app enquanto esperava: o anúncio fica para a próxima
      // abertura.
      if (WidgetsBinding.instance.lifecycleState !=
          AppLifecycleState.resumed) {
        _markAdOwed();
        return;
      }
    }
    final ad = _interstitial;
    if (ad == null || _fullScreenShowing) {
      // Não carregou a tempo: a próxima abertura do app compensa com o
      // anúncio de abertura.
      debugPrint('Anúncios: intersticial não carregou a tempo.');
      _markAdOwed();
      return;
    }
    _interstitial = null;
    _fullScreenShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _recordInterstitialShown(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _fullScreenShowing = false;
        onInterstitialDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        reportAdIssue(
          'interstitial_show',
          'code=${error.code} domain=${error.domain} ${error.message}',
        );
        ad.dispose();
        _fullScreenShowing = false;
        _markAdOwed();
      },
    );
    unawaited(ad.show());
  }

  /// O usuário salvou um registro e não viu o intersticial: por sorteio
  /// (`app_open_chance_percent`), fica um anúncio pendente que aparece na
  /// próxima abertura do app. Sorteado aqui, e não na abertura, para só
  /// carregar o anúncio quando ele de fato vai aparecer. Já deixa o anúncio
  /// carregando, para estar pronto se o app voltar do segundo plano.
  void _markAdOwed() {
    if (!AdsConfig.instance.appOpenEnabled) return;
    if (!_state.adOwed) {
      final chance = AdsConfig.instance.appOpenChancePercent;
      if (_random.nextInt(100) >= chance) {
        debugPrint('Anúncios: abertura não sorteada ($chance%).');
        return;
      }
      _state.adOwed = true;
      unawaited(_saveState());
    }
    _loadAppOpen();
  }

  /// Chamado na abertura do app (já com o consentimento resolvido) e ao
  /// voltar do segundo plano depois de [_appOpenMinBackground]. Exibe o
  /// anúncio de abertura se o usuário ficou devendo um anúncio.
  Future<void> _handleAppOpened() async {
    _openedAt = DateTime.now();
    prepareInterstitial();
    if (!await _appOpenDue()) return;
    final ad = _validAppOpen();
    if (ad != null) {
      _showAppOpen(ad);
    } else {
      // Carrega agora; se ficar pronto dentro da janela, é exibido.
      _loadAppOpen();
    }
  }

  Future<bool> _appOpenDue() async {
    if (!_shouldShowAds || !AdsConfig.instance.appOpenEnabled) return false;
    await ensureStateLoaded();
    if (!_state.adOwed || adFreeActive || _fullScreenShowing) return false;
    // Carência inicial também vale para o anúncio de abertura.
    if (await _inGracePeriod()) return false;
    // Só depois do login e do cadastro do veículo: antes disso o usuário
    // ainda está conhecendo o app.
    if (AuthenticationService.instance.currentUser == null) return false;
    try {
      if ((await VehicleStorageService().loadVehicles()).isEmpty) return false;
    } on Object {
      return false;
    }
    return true;
  }

  AppOpenAd? _validAppOpen() {
    final loadedAt = _appOpenLoadedAt;
    if (_appOpen != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) > _appOpenMaxAge) {
      _appOpen!.dispose();
      _appOpen = null;
    }
    return _appOpen;
  }

  void _loadAppOpen() {
    if (!_shouldShowAds ||
        !AdsConfig.instance.appOpenEnabled ||
        _loadingAppOpen ||
        _validAppOpen() != null) {
      return;
    }
    _loadingAppOpen = true;
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingAppOpen = false;
          _appOpen = ad;
          _appOpenLoadedAt = DateTime.now();
          unawaited(_showAppOpenIfStillOpening());
        },
        onAdFailedToLoad: (error) {
          _loadingAppOpen = false;
          reportAdIssue(
            'app_open_load',
            'code=${error.code} domain=${error.domain} ${error.message}',
          );
        },
      ),
    );
  }

  /// Exibe o anúncio recém-carregado só se o app acabou de abrir; senão ele
  /// fica guardado para a próxima abertura.
  Future<void> _showAppOpenIfStillOpening() async {
    final openedAt = _openedAt;
    if (openedAt == null ||
        DateTime.now().difference(openedAt) > _appOpenShowWindow ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    if (!await _appOpenDue()) return;
    final ad = _validAppOpen();
    if (ad != null) _showAppOpen(ad);
  }

  void _showAppOpen(AppOpenAd ad) {
    _appOpen = null;
    _fullScreenShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        // Pago o anúncio devido. O contador do intersticial não é zerado:
        // o próximo registro salvo ainda mostra o intersticial.
        _state.adOwed = false;
        unawaited(_saveState());
        _logEvent('ad_app_open_shown');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _fullScreenShowing = false;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        reportAdIssue(
          'app_open_show',
          'code=${error.code} domain=${error.domain} ${error.message}',
        );
        ad.dispose();
        _fullScreenShowing = false;
      },
    );
    unawaited(ad.show());
  }

  /// Se o usuário ainda está na carência inicial: salvou até
  /// AdsConfig.interstitialGraceRecords abastecimentos (somando
  /// [pendingFuelings], o que está sendo registrado). Em caso de erro na
  /// leitura, considera fora da carência para não suspender os anúncios.
  Future<bool> _inGracePeriod({int pendingFuelings = 0}) async {
    if (_graceOver) return false;
    final grace = AdsConfig.instance.interstitialGraceRecords;
    if (grace <= 0) return false;
    try {
      final saved = (await FuelingStorageService().loadFuelings()).length;
      if (saved > grace) _graceOver = true;
      return saved + pendingFuelings <= grace;
    } on Object {
      return false;
    }
  }

  /// Retorna o motivo que impede o intersticial agora, ou nulo se ele pode
  /// ser exibido. Só há duas regras: o contador de atividades e o período
  /// sem anúncios ganho no vídeo premiado.
  ///
  /// Com [pendingActivities] > 0 avalia o momento em que a atividade em
  /// andamento for salva (usado no pré-carregamento).
  String? _interstitialBlockedBy({int pendingActivities = 0}) {
    final config = AdsConfig.instance;
    final activities = _state.activitiesSinceInterstitial + pendingActivities;
    if (activities < config.interstitialActivitiesPerShow) {
      return 'contador $activities/${config.interstitialActivitiesPerShow}';
    }
    if (adFreeActive) return 'período sem anúncios em tela cheia';
    return null;
  }

  void _recordInterstitialShown() {
    _state.activitiesSinceInterstitial = 0;
    _state.adOwed = false;
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
    _fullScreenShowing = true;
    var earned = false;
    final completion = Completer<RewardedResult>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      // Não recarrega depois de exibir: o vídeo só é pedido quando o usuário
      // abre uma tela que oferece a recompensa (menu "Mais" ou convite).
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingRewarded = false;
        _fullScreenShowing = false;
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
        _fullScreenShowing = false;
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

  /// Mostra o vídeo premiado para liberar um recurso do plano gratuito
  /// (ver FreePlanService), sem conceder as horas sem anúncios em tela cheia
  /// do fluxo de [showRewarded]. Devolve `true` só quando a recompensa foi
  /// de fato ganha (vídeo assistido até o fim).
  ///
  /// Se não houver vídeo disponível agora (sem rede, sem consentimento ou
  /// sem estoque no AdMob) ou se ele falhar ao abrir, devolve `true` também:
  /// o usuário não deve ficar travado por um anúncio que não existe.
  ///
  /// Cada chamada registra `rewarded_unlock` com [feature] (o recurso
  /// liberado) e `result`: earned, not_earned, unavailable, show_failed ou
  /// busy (outro vídeo já aberto).
  Future<bool> unlockWithRewarded({String feature = 'unknown'}) async {
    void logResult(String result) => AnalyticsService.event(
      'rewarded_unlock',
      {'feature': feature, 'result': result},
    );
    if (_showingRewarded) {
      logResult('busy');
      return false;
    }
    if (!rewardedReady) {
      _rewarded?.dispose();
      _rewarded = null;
      loadRewarded();
      debugPrint('Anúncios: vídeo premiado indisponível; liberando mesmo assim.');
      logResult('unavailable');
      return true;
    }
    await ensureStateLoaded();
    final ad = _rewarded!;
    _rewarded = null;
    _showingRewarded = true;
    _fullScreenShowing = true;
    var earned = false;
    final completion = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      // Não concede horas sem anúncios: só libera o recurso pedido.
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingRewarded = false;
        _fullScreenShowing = false;
        if (!completion.isCompleted) {
          logResult(earned ? 'earned' : 'not_earned');
          completion.complete(earned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        reportAdIssue(
          'rewarded_unlock_show',
          'code=${error.code} domain=${error.domain} ${error.message}',
        );
        ad.dispose();
        _showingRewarded = false;
        _fullScreenShowing = false;
        // Falhou ao exibir: libera para não travar o usuário.
        if (!completion.isCompleted) {
          logResult('show_failed');
          completion.complete(true);
        }
      },
    );
    unawaited(
      ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
          _logEvent('ad_rewarded_unlock_earned');
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
      FirebaseAnalytics.instance.logEvent(name: name).ignore();
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
        changed = true;
      }
    } on Object catch (error) {
      debugPrint('Não foi possível ler o contador de anúncios: $error');
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
    final completion = _interstitialLoad = Completer<void>();
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
          _interstitialLoadedAt = DateTime.now();
          completion.complete();
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          completion.complete();
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
    // Lê o estado logo na abertura, para já saber se há período sem anúncios
    // ativo.
    unawaited(ensureStateLoaded().then((_) => notifyListeners()));

    await MobileAds.instance.initialize();
    await _requestConsent();
    _consentChecked = true;
    notifyListeners();
    if (!_canRequestAds) {
      reportAdIssue('consent_blocked', 'canRequestAds=false após o UMP');
    }
    // Abertura do app: anúncio de abertura, se devido, e intersticial pronto
    // para o registro desta sessão. Voltar do segundo plano depois de um
    // tempo conta como nova abertura (o anúncio carregado também expira).
    unawaited(_handleAppOpened());
    // initialize() roda uma vez só, então o listener é registrado uma vez.
    AppLifecycleListener(
      onHide: () => _hiddenAt = DateTime.now(),
      onShow: () {
        // Abriu sem internet e o UMP falhou: tenta de novo a cada volta ao
        // app, para os anúncios voltarem sem precisar reiniciá-lo.
        if (!_canRequestAds) unawaited(_requestConsent());
        final hiddenAt = _hiddenAt;
        _hiddenAt = null;
        if (hiddenAt == null || _fullScreenShowing) return;
        if (DateTime.now().difference(hiddenAt) >= _appOpenMinBackground) {
          unawaited(_handleAppOpened());
        } else {
          prepareInterstitial();
        }
      },
    );
  }

  /// Atualiza o consentimento no UMP e mostra o formulário, se necessário.
  Future<void> _requestConsent() async {
    if (_requestingConsent) return;
    _requestingConsent = true;
    try {
      await _requestConsentOnce();
    } finally {
      _requestingConsent = false;
    }
  }

  Future<void> _requestConsentOnce() async {
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
    // Nada é pré-carregado aqui: intersticial e vídeo premiado carregados na
    // abertura do app quase nunca eram exibidos (o usuário abre, consulta e
    // fecha), o que derrubava a taxa de exibição no AdMob.
    notifyListeners();
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
  DateTime? adFreeUntil;
  DateTime? lastPremiumAfterAdAt;
  // Salvou um registro sem ver o intersticial: a próxima abertura mostra o
  // anúncio de abertura.
  bool adOwed = false;

  // Chaves antigas (limite diário, intervalo, carência) que ainda existam no
  // arquivo são ignoradas e somem na próxima gravação.
  void readJson(Map<String, dynamic> json) {
    activitiesSinceInterstitial =
        (json['activitiesSinceInterstitial'] as num?)?.toInt() ?? 0;
    adFreeUntil = _date(json['adFreeUntil']);
    lastPremiumAfterAdAt = _date(json['lastPremiumAfterAdAt']);
    adOwed = json['adOwed'] as bool? ?? false;
  }

  Map<String, dynamic> toJson() => {
    'activitiesSinceInterstitial': activitiesSinceInterstitial,
    'adFreeUntil': adFreeUntil?.toIso8601String(),
    'lastPremiumAfterAdAt': lastPremiumAfterAdAt?.toIso8601String(),
    'adOwed': adOwed,
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
