import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'ads_service.dart';

/// Limites dos anúncios ajustáveis pelo Firebase Remote Config, sem publicar
/// nova versão. O app funciona só com os valores padrão abaixo, mesmo que
/// nenhum parâmetro tenha sido publicado no console.
class AdsConfig {
  AdsConfig._();

  static final AdsConfig instance = AdsConfig._();

  // Chaves publicadas no Remote Config.
  static const _activitiesPerShow = 'interstitial_activities_per_show';
  static const _minIntervalMinutes = 'interstitial_min_interval_minutes';
  static const _maxPerDay = 'interstitial_max_per_day';
  static const _graceDays = 'interstitial_grace_days';
  static const _premiumAfterAdEnabled = 'premium_after_ad_enabled';
  static const _premiumAfterAdIntervalDays = 'premium_after_ad_interval_days';
  static const _rewardedEnabled = 'rewarded_enabled';
  static const _rewardedAdFreeHours = 'rewarded_ad_free_hours';
  static const _nativeEnabled = 'native_enabled';
  static const _nativeEveryNItems = 'native_every_n_items';
  static const _nativeMinItems = 'native_min_items';
  static const _nativeMaxPerScreen = 'native_max_per_screen';

  /// Valores usados enquanto o Remote Config não respondeu, se ele falhar ou
  /// se o parâmetro não existir no console.
  static const defaults = <String, Object>{
    _activitiesPerShow: 1,
    _minIntervalMinutes: 3,
    _maxPerDay: 5,
    _graceDays: 2,
    _premiumAfterAdEnabled: true,
    _premiumAfterAdIntervalDays: 7,
    _rewardedEnabled: true,
    _rewardedAdFreeHours: 3,
    _nativeEnabled: true,
    _nativeEveryNItems: 7,
    _nativeMinItems: 3,
    _nativeMaxPerScreen: 3,
  };

  bool _initialized = false;
  // Só fica verdadeiro depois que os padrões foram registrados no SDK; antes
  // disso (ou se o Firebase falhar) os getters leem direto de [defaults].
  bool _remoteReady = false;

  /// Registra os padrões e busca os valores publicados em segundo plano,
  /// sem atrasar a abertura do app.
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    unawaited(_setup());
  }

  Future<void> _setup() async {
    try {
      final remote = FirebaseRemoteConfig.instance;
      await remote.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          // Em debug busca quase sempre, para testar mudanças do console.
          minimumFetchInterval: kReleaseMode
              ? const Duration(hours: 12)
              : const Duration(minutes: 1),
        ),
      );
      await remote.setDefaults(defaults);
      _remoteReady = true;
      await remote.fetchAndActivate();
    } on Object catch (error) {
      // Sem rede ou Firebase indisponível: seguem os valores padrão.
      AdsService.instance.reportAdIssue('remote_config', '$error');
    }
  }

  int _int(String key) {
    if (_remoteReady) {
      try {
        return FirebaseRemoteConfig.instance.getInt(key);
      } on Object {
        // Cai no padrão local abaixo.
      }
    }
    return defaults[key]! as int;
  }

  bool _bool(String key) {
    if (_remoteReady) {
      try {
        return FirebaseRemoteConfig.instance.getBool(key);
      } on Object {
        // Cai no padrão local abaixo.
      }
    }
    return defaults[key]! as bool;
  }

  /// Registros necessários para liberar um intersticial (mínimo 1).
  int get interstitialActivitiesPerShow =>
      math.max(1, _int(_activitiesPerShow));

  /// Intervalo mínimo entre dois intersticiais.
  Duration get interstitialMinInterval =>
      Duration(minutes: math.max(0, _int(_minIntervalMinutes)));

  /// Máximo de intersticiais por dia (data local).
  int get interstitialMaxPerDay => math.max(0, _int(_maxPerDay));

  /// Dias, contados da primeira abertura, sem nenhum intersticial.
  int get interstitialGraceDays => math.max(0, _int(_graceDays));

  /// Liga/desliga o convite Premium depois do intersticial.
  bool get premiumAfterAdEnabled => _bool(_premiumAfterAdEnabled);

  /// Intervalo mínimo entre dois convites Premium após anúncio.
  Duration get premiumAfterAdInterval =>
      Duration(days: math.max(0, _int(_premiumAfterAdIntervalDays)));

  /// Liga/desliga o vídeo premiado ("horas sem anúncios em tela cheia").
  bool get rewardedEnabled => _bool(_rewardedEnabled);

  /// Horas sem anúncios em tela cheia ganhas ao assistir ao vídeo.
  int get rewardedAdFreeHours => math.max(1, _int(_rewardedAdFreeHours));

  /// Liga/desliga os anúncios nativos nas listas.
  bool get nativeEnabled => _bool(_nativeEnabled);

  /// Um nativo a cada N itens da lista (mínimo 1).
  int get nativeEveryNItems => math.max(1, _int(_nativeEveryNItems));

  /// A lista precisa ter ao menos N itens para exibir nativos.
  int get nativeMinItems => math.max(0, _int(_nativeMinItems));

  /// Máximo de nativos por tela.
  int get nativeMaxPerScreen => math.max(0, _int(_nativeMaxPerScreen));
}
