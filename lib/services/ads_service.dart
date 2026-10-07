import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  bool _initialized = false;
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

  Future<void> initialize() async {
    if (!supported || _initialized) return;
    _initialized = true;

    await MobileAds.instance.initialize();
    final completion = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) async {
          await _refreshConsentState();
          if (!completion.isCompleted) completion.complete();
        });
      },
      (_) async {
        await _refreshConsentState();
        if (!completion.isCompleted) completion.complete();
      },
    );

    await completion.future.timeout(
      const Duration(seconds: 12),
      onTimeout: _refreshConsentState,
    );
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
