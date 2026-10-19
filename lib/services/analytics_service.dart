import 'dart:convert';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'access_service.dart';
import 'vehicle_storage_service.dart';

/// Estatísticas de uso no Firebase Analytics: em qual tela o usuário está e o
/// que ele toca. Nunca envia conteúdo digitado (nome de veículo, placa,
/// valores, observações, e-mail...): só as chaves da lista [_allowedKeys],
/// com textos curtos e fixos definidos no código.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  /// Instância única do observador, para não recriar a cada rebuild do
  /// MaterialApp.
  static final _observer = FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
    nameExtractor: _routeName,
  );

  /// Observador das rotas nomeadas (RouteSettings.name), usado no
  /// MaterialApp para registrar o screen_view automaticamente.
  static FirebaseAnalyticsObserver observer() => _observer;

  /// Última tela registrada manualmente via [screen]; usada para o
  /// observador pular o próximo screen_view automático com o mesmo nome e
  /// evitar duplicidade.
  static String? _manualScreen;

  /// Extrai o nome da rota para o observador. A marca manual (ver [screen])
  /// só vale para o próximo evento do observador: é consumida aqui mesmo
  /// quando o nome não corresponde, para não ficar pendente e suprimir um
  /// screen_view legítimo posterior com o mesmo nome.
  static String? _routeName(RouteSettings settings) {
    // A rota raiz ('/') é a tela de apresentação; usa o nome 'presentation'
    // para ficar consistente com os demais eventos de tela.
    final name = settings.name == '/' ? 'presentation' : settings.name;
    final pending = _manualScreen;
    _manualScreen = null;
    if (name != null && name == pending) return null;
    return name;
  }

  /// Únicas chaves de parâmetro aceitas; qualquer outra é descartada.
  static const _allowedKeys = {
    'screen',
    'element',
    'source',
    'feature',
    'plan',
    'offer_tag',
    'period',
    'reason',
    'result',
    'is_trial',
    'vehicles_count',
  };

  /// Textos acima deste tamanho são cortados.
  static const _maxTextLength = 40;

  bool _initialized = false;
  String? _lastPlan;
  String? _lastVehiclesBucket;
  String? _lastDaysBucket;

  /// Atualiza as propriedades do usuário na abertura do app e passa a
  /// acompanhar mudanças de plano, de quantidade de veículos e de dias desde
  /// a instalação.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _updatePlan();
    AccessService.instance.addListener(_updatePlan);
    VehicleStorageService.vehicleCount.addListener(
      () => updateVehiclesCount(VehicleStorageService.vehicleCount.value),
    );
    try {
      // A leitura já sincroniza VehicleStorageService.vehicleCount, que
      // dispara o listener acima — exceto no caso 0→0 (sem veículos), em que
      // o ValueNotifier não notifica; por isso a chamada explícita abaixo,
      // que o dedup de _lastVehiclesBucket impede de duplicar quando o
      // listener já tiver disparado.
      await VehicleStorageService().loadVehicles();
      updateVehiclesCount(VehicleStorageService.vehicleCount.value);
    } on Object {
      // Sem veículos legíveis: a propriedade fica para a próxima gravação.
    }
    await _updateDaysSinceInstall();
    // currentUser ainda pode ser nulo aqui (login ainda não concluído); a
    // mudança de usuário reavalia a base (criação da conta x primeira
    // abertura).
    FirebaseAuth.instance.authStateChanges().listen(
      (_) => _updateDaysSinceInstall(),
    );
  }

  /// Dias desde a instalação, em faixas (0-7, 8-30, 31+). Usa a data de
  /// criação da conta como base; sem usuário (ou sem a data), usa a data da
  /// primeira abertura salva localmente em [_firstOpenAt].
  Future<void> _updateDaysSinceInstall() async {
    try {
      // Sempre lida, para garantir que o arquivo exista e a alternativa
      // funcione mesmo quando o usuário já está logado desde a abertura.
      final firstOpen = await _firstOpenAt();
      final creationTime =
          FirebaseAuth.instance.currentUser?.metadata.creationTime;
      final baseDate = creationTime ?? firstOpen;
      final days = DateTime.now().difference(baseDate).inDays;
      final bucket = switch (days) {
        <= 7 => '0-7',
        <= 30 => '8-30',
        _ => '31+',
      };
      if (bucket == _lastDaysBucket) return;
      _lastDaysBucket = bucket;
      _setUserProperty('days_since_install', bucket);
    } on Object {
      // Data de criação/primeira abertura indisponível: só estatística.
    }
  }

  /// Registra a tela atual manualmente (telas sem rota própria).
  static void screen(String name) {
    try {
      final clipped = _clip(name);
      // Marca como registrada manualmente para o observador pular o
      // próximo screen_view automático com o mesmo nome.
      _manualScreen = clipped;
      FirebaseAnalytics.instance.logScreenView(screenName: clipped).ignore();
    } on Object {
      // Firebase indisponível: o evento é só estatística.
    }
  }

  /// Toque em um elemento da interface; [element] é sempre um nome fixo.
  static void tap(
    String element, {
    String? screen,
    Map<String, Object?> params = const {},
  }) => event('ui_tap', {...params, 'element': element, 'screen': screen});

  /// Evento genérico, já filtrado pela lista de chaves aceitas.
  static void event(String name, [Map<String, Object?> params = const {}]) {
    try {
      // .ignore() descarta erros assíncronos do Future (o try/catch aqui só
      // captura erros síncronos), para não virarem crash fatal no Crashlytics.
      FirebaseAnalytics.instance
          .logEvent(name: name, parameters: _sanitize(params))
          .ignore();
    } on Object {
      // Firebase indisponível: o evento é só estatística.
    }
  }

  /// Quantidade de veículos em faixas (0, 1, 2-3, 4+), chamada na abertura e
  /// sempre que a lista de veículos é lida ou gravada.
  void updateVehiclesCount(int count) {
    final bucket = switch (count) {
      0 => '0',
      1 => '1',
      <= 3 => '2-3',
      _ => '4+',
    };
    if (bucket == _lastVehiclesBucket) return;
    _lastVehiclesBucket = bucket;
    _setUserProperty('vehicles_count', bucket);
  }

  /// Plano do usuário, por ordem de precedência: assinante pago, Premium
  /// temporário (beta), modo gratuito ou, por fim, gratuito comum.
  void _updatePlan() {
    final access = AccessService.instance;
    final plan = access.paidSubscriptionActive
        ? 'premium_paid'
        : access.betaPremiumActive
        ? 'premium_beta'
        : AccessService.freeModeEnabled
        ? 'free_mode'
        : 'free';
    if (plan == _lastPlan) return;
    _lastPlan = plan;
    _setUserProperty('plan', plan);
  }

  static void _setUserProperty(String name, String value) {
    try {
      FirebaseAnalytics.instance
          .setUserProperty(name: name, value: value)
          .ignore();
    } on Object {
      // Firebase indisponível: a propriedade é só estatística.
    }
  }

  /// Mantém só as chaves aceitas; o Analytics aceita apenas texto ou número,
  /// então booleanos viram 1/0 e nulos são removidos.
  static Map<String, Object>? _sanitize(Map<String, Object?> params) {
    final result = <String, Object>{};
    params.forEach((key, value) {
      if (!_allowedKeys.contains(key) || value == null) return;
      result[key] = switch (value) {
        final bool flag => flag ? 1 : 0,
        final num number => number,
        _ => _clip(value.toString()),
      };
    });
    return result.isEmpty ? null : result;
  }

  static String _clip(String text) =>
      text.length > _maxTextLength ? text.substring(0, _maxTextLength) : text;

  /// Data da primeira abertura, guardada localmente na primeira execução.
  Future<DateTime> _firstOpenAt() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}analytics.json',
    );
    if (await file.exists()) {
      try {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final saved = DateTime.tryParse(json['firstOpenAt'] as String? ?? '');
        if (saved != null) return saved;
      } on Object {
        // Arquivo corrompido: recria com a data de hoje.
      }
    }
    final now = DateTime.now();
    await file.writeAsString(
      jsonEncode({'firstOpenAt': now.toIso8601String()}),
      flush: true,
    );
    return now;
  }
}
