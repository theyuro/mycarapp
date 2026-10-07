import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';

import 'access_service.dart';

class AdsService extends ChangeNotifier {
  AdsService._();

  static final AdsService instance = AdsService._();

  static const _androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';
  // Bloco de banner de produção (Android). Usado só em release: em debug
  // seguem os IDs de teste, para não gerar tráfego inválido no AdMob.
  static const _androidProductionBannerId =
      'ca-app-pub-3009025921589541/3136303292';
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

  /// Quantas atividades principais (abastecimento, manutenção ou despesa
  /// novos) o usuário registra entre um intersticial e outro.
  static const activitiesPerInterstitial = 2;

  bool _initialized = false;
  InterstitialAd? _interstitial;
  DateTime? _interstitialLoadedAt;
  // O AdMob invalida um intersticial carregado após 1 hora; acima disto ele
  // é descartado e recarregado em vez de falhar na exibição.
  static const _interstitialMaxAge = Duration(minutes: 55);
  bool _loadingInterstitial = false;
  // Persistido em disco: o app é de pouco uso, então o contador precisa
  // sobreviver ao fechamento para o intersticial chegar a aparecer.
  int _activitiesSinceInterstitial = 0;
  Future<void>? _counterLoaded;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;

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

  String get bannerAdUnitId {
    if (_configuredBannerId.isNotEmpty) return _configuredBannerId;
    if (kReleaseMode && defaultTargetPlatform == TargetPlatform.android) {
      return _androidProductionBannerId;
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

  bool get _shouldShowAds =>
      canRequestAds &&
      (AccessService.freeModeEnabled || !AccessService.instance.hasAccess);

  /// Registra uma atividade principal concluída e, a cada
  /// [activitiesPerInterstitial] atividades, exibe o intersticial.
  void registerMainActivity() => unawaited(_registerMainActivity());

  Future<void> _registerMainActivity() async {
    if (!_shouldShowAds) return;
    await (_counterLoaded ??= _loadCounter());
    _activitiesSinceInterstitial++;
    unawaited(_saveCounter());
    if (_activitiesSinceInterstitial < activitiesPerInterstitial) {
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
    _activitiesSinceInterstitial = 0;
    unawaited(_saveCounter());
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
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

  Future<File> _counterFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}interstitial_counter.txt',
    );
  }

  Future<void> _loadCounter() async {
    try {
      final file = await _counterFile();
      if (!await file.exists()) return;
      _activitiesSinceInterstitial =
          int.tryParse((await file.readAsString()).trim()) ?? 0;
    } on Object catch (error) {
      debugPrint('Não foi possível ler o contador de anúncios: $error');
    }
  }

  Future<void> _saveCounter() async {
    try {
      final file = await _counterFile();
      await file.writeAsString('$_activitiesSinceInterstitial');
    } on Object catch (error) {
      debugPrint('Não foi possível salvar o contador de anúncios: $error');
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
