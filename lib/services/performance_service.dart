import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/performance_record.dart';

/// 1 g em m/s² (aceleração da gravidade padrão).
const _gravityMs2 = 9.80665;

/// Vetor 3D simples, só para a calibração e a projeção da Força G (sem
/// depender de um pacote de matemática externo).
class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  factory _Vec3.zero() => const _Vec3(0, 0, 0);

  final double x;
  final double y;
  final double z;

  _Vec3 operator +(_Vec3 other) => _Vec3(x + other.x, y + other.y, z + other.z);
  _Vec3 operator -(_Vec3 other) => _Vec3(x - other.x, y - other.y, z - other.z);
  _Vec3 operator *(double scale) => _Vec3(x * scale, y * scale, z * scale);

  double dot(_Vec3 other) => x * other.x + y * other.y + z * other.z;

  _Vec3 cross(_Vec3 other) => _Vec3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  double get length => math.sqrt(x * x + y * y + z * z);

  _Vec3 get normalized {
    final len = length;
    return len < 1e-6 ? _Vec3.zero() : this * (1 / len);
  }

  Map<String, double> toJson() => {'x': x, 'y': y, 'z': z};

  static _Vec3 fromJson(Map<String, dynamic> json) => _Vec3(
    (json['x'] as num).toDouble(),
    (json['y'] as num).toDouble(),
    (json['z'] as num).toDouble(),
  );
}

/// Uma amostra do acelerômetro bruto com o instante em que foi lida, usada
/// só durante a calibração, para medir a estabilidade numa janela de tempo.
class _TimedSample {
  const _TimedSample(this.time, this.value);
  final DateTime time;
  final _Vec3 value;
}

/// Onde o celular está montado no carro. Define o eixo "para frente" a
/// partir do vetor de gravidade (up) medido na calibração — ver
/// [PerformanceService.calibrate].
enum PhonePosition { uprightInHolder, lyingFlat }

extension on PhonePosition {
  /// Vetor de referência "para frente" no referencial do Android (x para a
  /// direita da tela, y para o topo da tela, z saindo da tela), antes de
  /// ser projetado no plano horizontal do carro.
  _Vec3 get forwardReference => switch (this) {
    // Tela voltada para o motorista: a frente do carro é a parte de trás do
    // celular, ou seja, o eixo -z.
    PhonePosition.uprightInHolder => const _Vec3(0, 0, -1),
    // Tela para cima, topo do celular apontando para a frente do carro:
    // eixo +y.
    PhonePosition.lyingFlat => const _Vec3(0, 1, 0),
  };
}

/// Eixos derivados da calibração: "para frente" e "para a direita" do
/// carro, no referencial do acelerômetro do celular.
class _CalibrationAxes {
  const _CalibrationAxes({required this.forward, required this.right});

  final _Vec3 forward;
  final _Vec3 right;

  Map<String, dynamic> toJson() => {
    'forward': forward.toJson(),
    'right': right.toJson(),
  };

  static _CalibrationAxes fromJson(Map<String, dynamic> json) =>
      _CalibrationAxes(
        forward: _Vec3.fromJson(json['forward'] as Map<String, dynamic>),
        right: _Vec3.fromJson(json['right'] as Map<String, dynamic>),
      );
}

/// Passo atual da calibração, para a tela mostrar a instrução certa.
enum CalibrationStep { idle, waiting, failed }

/// Por que a calibração falhou (ou [none] quando não falhou).
enum CalibrationFailureReason { none, noSensorData, unstable, positionMismatch }

/// Qualidade do sinal de GPS, para o cartão "GPS" da tela.
enum GpsSignal { searching, weak, ok }

/// Estado do teste de 0–100 km/h.
enum ZeroToHundredState { idle, armed, measuring, completed, cancelled }

/// Um ponto (tempo, velocidade) amostrado durante o teste 0–100, usado para
/// interpolar o instante exato em que a velocidade cruza 60 e 100 km/h.
class _SpeedSample {
  const _SpeedSample(this.elapsedMs, this.speedKmh);
  final int elapsedMs;
  final double speedKmh;
}

/// Sensores e medição da tela Desempenho: Força G (acelerômetro), velocidade
/// (GPS) e o teste de 0–100 km/h. Uma instância vive só enquanto a tela
/// estiver aberta: [start] liga os sensores e [stop]/[dispose] desligam tudo.
///
/// Não há nenhum envio a servidor: tudo fica no aparelho (ver
/// [PerformanceRecord] e a calibração, ambos em arquivo JSON local).
class PerformanceService extends ChangeNotifier {
  PerformanceService({required this.vehicleId});

  final String vehicleId;

  StreamSubscription<UserAccelerometerEvent>? _userAccelSubscription;
  StreamSubscription<AccelerometerEvent>? _rawAccelFallbackSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _userAccelWatchdog;
  Timer? _positionFallbackTimer;

  _CalibrationAxes? _axes;
  _Vec3 _filteredAccel = _Vec3.zero();
  static const _lowPassAlpha = 0.25;

  /// Vetor de gravidade estimado quando o acelerômetro linear nativo não
  /// está disponível (ver [_fallbackToRawAccel]).
  _Vec3 _gravityEstimate = _Vec3.zero();

  bool get calibrated => _axes != null;

  // ---------------------------------------------------------------------
  // Diagnóstico (toque longo no título da tela)
  // ---------------------------------------------------------------------

  /// `true` quando a leitura vem de userAccelerometerEventStream (sensor
  /// linear nativo); `false` quando caiu para o modo bruto com gravidade
  /// estimada (ver item B5 do Prompt 2).
  bool usingLinearAccelSensor = true;

  /// Taxa de leituras do acelerômetro por segundo, medida numa janela de 1 s.
  double accelHz = 0;
  int _accelSampleCount = 0;
  DateTime _accelRateWindowStart = DateTime.now();

  DateTime? lastPositionAt;
  double? lastPositionAccuracy;
  double? lastSpeedAccuracy;

  // ---------------------------------------------------------------------
  // Velocímetro
  // ---------------------------------------------------------------------

  double speedKmh = 0;
  double maxSpeedKmh = 0;

  /// `null` enquanto não souber se a permissão foi concedida.
  bool? gpsAvailable;

  GpsSignal gpsSignal = GpsSignal.searching;

  // ---------------------------------------------------------------------
  // Força G
  // ---------------------------------------------------------------------

  /// Módulo da aceleração linear filtrada, em g. Funciona mesmo sem
  /// calibração (item B6 do Prompt 2): o radar não fica "morto" enquanto o
  /// usuário calibra.
  double resultantG = 0;

  /// Positivo = aceleração para a frente; negativo = frenagem. Só é
  /// diferente de zero com calibração válida.
  double longitudinalG = 0;

  /// Positivo/negativo = direita/esquerda. Só é diferente de zero com
  /// calibração válida.
  double lateralG = 0;

  double peakResultantG = 0;
  double peakLateralG = 0;
  double peakBrakingG = 0;

  // ---------------------------------------------------------------------
  // Calibração
  // ---------------------------------------------------------------------

  CalibrationStep calibrationStep = CalibrationStep.idle;
  CalibrationFailureReason calibrationFailure = CalibrationFailureReason.none;

  /// Posição do celular no carro, escolhida pelo usuário e salva por
  /// veículo; o padrão é "em pé no suporte".
  PhonePosition phonePosition = PhonePosition.uprightInHolder;

  StreamSubscription<AccelerometerEvent>? _calibrationSubscription;
  Timer? _calibrationNoDataTimer;
  Timer? _calibrationGiveUpTimer;
  int _calibrationGeneration = 0;

  /// Troca a posição do celular, salva a escolha por veículo e recalibra
  /// (zera pico e rastro ao ter sucesso).
  Future<void> setPhonePosition(PhonePosition position) async {
    if (phonePosition == position) return;
    phonePosition = position;
    notifyListeners();
    // Guarda já a posição escolhida, mesmo que a calibração a seguir falhe.
    await _saveCalibration();
    await calibrate();
  }

  /// Calibra em um único passo (sem a etapa de "acelerar para a frente" do
  /// Prompt 1, que exigia o carro já em movimento e falhava parado ou em
  /// casa): espera o celular ficar parado e fixo, usando o acelerômetro
  /// bruto (com gravidade), e deriva os eixos "para frente" e "direita" a
  /// partir da posição escolhida ([phonePosition]).
  ///
  /// Mensagens de falha específicas (ver [calibrationFailure]):
  /// - [CalibrationFailureReason.noSensorData]: nenhuma leitura do
  ///   acelerômetro em 2 s, ou erro no stream.
  /// - [CalibrationFailureReason.unstable]: o celular não ficou parado por
  ///   1,5 s dentro do limite de 10 s.
  /// - [CalibrationFailureReason.positionMismatch]: com o celular parado, o
  ///   eixo "para frente" calculado ficou fraco demais para a posição
  ///   escolhida (provavelmente a posição marcada está errada).
  Future<bool> calibrate() async {
    await _cancelCalibration();
    final generation = ++_calibrationGeneration;
    calibrationStep = CalibrationStep.waiting;
    calibrationFailure = CalibrationFailureReason.none;
    notifyListeners();

    final samples = <_TimedSample>[];
    var sawAnyEvent = false;
    final completer = Completer<bool>();

    void finish(bool success, [CalibrationFailureReason reason = CalibrationFailureReason.none]) {
      if (completer.isCompleted) return;
      _calibrationNoDataTimer?.cancel();
      _calibrationGiveUpTimer?.cancel();
      unawaited(_calibrationSubscription?.cancel());
      _calibrationSubscription = null;
      if (!success) calibrationFailure = reason;
      completer.complete(success);
    }

    // Sem nenhuma leitura em 2 s: aparelho sem acelerômetro funcional.
    _calibrationNoDataTimer = Timer(const Duration(seconds: 2), () {
      if (!sawAnyEvent) finish(false, CalibrationFailureReason.noSensorData);
    });
    // Celular mexendo demais: espera a estabilidade em vez de falhar na
    // hora, mas desiste depois de 10 s.
    _calibrationGiveUpTimer = Timer(const Duration(seconds: 10), () {
      finish(false, CalibrationFailureReason.unstable);
    });

    _calibrationSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      (event) {
        sawAnyEvent = true;
        _calibrationNoDataTimer?.cancel();
        final now = DateTime.now();
        samples.add(_TimedSample(now, _Vec3(event.x, event.y, event.z)));
        samples.removeWhere(
          (item) => now.difference(item.time) > const Duration(milliseconds: 1500),
        );
        // Poucas amostras ainda: espera a janela de 1,5 s se formar.
        if (samples.length < 8) return;

        final meanVector = samples.fold<_Vec3>(
          _Vec3.zero(),
          (sum, item) => sum + item.value,
        ) * (1 / samples.length);
        final magnitudes = samples.map((item) => item.value.length).toList();
        final meanMagnitude = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
        final variance = magnitudes.fold<double>(
          0,
          (sum, m) => sum + (m - meanMagnitude) * (m - meanMagnitude),
        ) / magnitudes.length;
        final stdDev = math.sqrt(variance);
        final stable = stdDev < 0.15 && meanMagnitude >= 8.5 && meanMagnitude <= 11.0;
        if (!stable) return;

        final up = meanVector.normalized;
        final f0 = phonePosition.forwardReference;
        final forwardRaw = f0 - up * f0.dot(up);
        if (forwardRaw.length < 0.3) {
          // Posição incompatível com a opção escolhida: a projeção do eixo
          // de referência no plano horizontal ficou fraca demais.
          finish(false, CalibrationFailureReason.positionMismatch);
          return;
        }
        final forward = forwardRaw.normalized;
        final right = forward.cross(up).normalized;
        _axes = _CalibrationAxes(forward: forward, right: right);
        finish(true);
      },
      onError: (_) => finish(false, CalibrationFailureReason.noSensorData),
    );

    final success = await completer.future;
    // Uma calibração mais nova já começou (ex.: usuário trocou a posição de
    // novo): descarta este resultado.
    if (generation != _calibrationGeneration) return false;
    if (success) {
      _filteredAccel = _Vec3.zero();
      resetSessionPeaks();
      calibrationStep = CalibrationStep.idle;
      await _saveCalibration();
    } else {
      calibrationStep = CalibrationStep.failed;
    }
    notifyListeners();
    return success;
  }

  Future<void> _cancelCalibration() async {
    _calibrationNoDataTimer?.cancel();
    _calibrationGiveUpTimer?.cancel();
    await _calibrationSubscription?.cancel();
    _calibrationSubscription = null;
  }

  /// Zera os picos da sessão (chamado ao calibrar e ao abrir a tela).
  void resetSessionPeaks() {
    peakResultantG = 0;
    peakLateralG = 0;
    peakBrakingG = 0;
    maxSpeedKmh = 0;
  }

  // ---------------------------------------------------------------------
  // Teste 0–100 km/h
  // ---------------------------------------------------------------------

  ZeroToHundredState testState = ZeroToHundredState.idle;
  PerformanceFuelType? testFuel;
  double? zeroToSixtySeconds;
  double? zeroToHundredSeconds;

  final _stopwatch = Stopwatch();
  final List<_SpeedSample> _testSamples = [];
  double _peakResultantAtTestStart = 0;
  double _peakLateralAtTestStart = 0;
  double _peakBrakingAtTestStart = 0;

  /// Callback chamado quando o teste termina (concluído ou cancelado), para
  /// a tela registrar o Analytics e salvar o recorde.
  void Function(PerformanceRecord? record, String result)? onTestFinished;

  /// Arma o teste: a medição começa quando a velocidade passar de 3 km/h.
  void armZeroToHundred(PerformanceFuelType fuel) {
    testFuel = fuel;
    testState = ZeroToHundredState.armed;
    zeroToSixtySeconds = null;
    zeroToHundredSeconds = null;
    _testSamples.clear();
    _stopwatch
      ..reset()
      ..stop();
    _peakResultantAtTestStart = peakResultantG;
    _peakLateralAtTestStart = peakLateralG;
    _peakBrakingAtTestStart = peakBrakingG;
    notifyListeners();
  }

  void cancelZeroToHundred() {
    if (testState == ZeroToHundredState.idle) return;
    testState = ZeroToHundredState.idle;
    _stopwatch
      ..reset()
      ..stop();
    notifyListeners();
  }

  void _onSpeedSample(double kmh) {
    if (testState == ZeroToHundredState.armed) {
      if (kmh >= 3) {
        _stopwatch
          ..reset()
          ..start();
        _testSamples
          ..clear()
          ..add(const _SpeedSample(0, 0));
        testState = ZeroToHundredState.measuring;
      }
      notifyListeners();
      return;
    }
    if (testState != ZeroToHundredState.measuring) return;
    final elapsed = _stopwatch.elapsedMilliseconds;
    final previous = _testSamples.isEmpty ? null : _testSamples.last;
    _testSamples.add(_SpeedSample(elapsed, kmh));
    if (previous != null && previous.speedKmh < 60 && kmh >= 60) {
      zeroToSixtySeconds = _interpolateSeconds(previous, _testSamples.last, 60);
    }
    if (previous != null && previous.speedKmh < 100 && kmh >= 100) {
      zeroToHundredSeconds = _interpolateSeconds(
        previous,
        _testSamples.last,
        100,
      );
      _finishZeroToHundred(cancelled: false);
      return;
    }
    if (elapsed > 500 && kmh < 2) {
      // Velocidade voltou a zero antes de completar: cancela.
      _finishZeroToHundred(cancelled: true);
      return;
    }
    notifyListeners();
  }

  double _interpolateSeconds(_SpeedSample before, _SpeedSample after, double target) {
    final speedDelta = after.speedKmh - before.speedKmh;
    final ratio = speedDelta <= 0
        ? 0.0
        : ((target - before.speedKmh) / speedDelta).clamp(0.0, 1.0);
    final timeMs = before.elapsedMs + (after.elapsedMs - before.elapsedMs) * ratio;
    return timeMs / 1000;
  }

  void _finishZeroToHundred({required bool cancelled}) {
    _stopwatch.stop();
    if (cancelled) {
      testState = ZeroToHundredState.cancelled;
      onTestFinished?.call(null, 'cancelled');
      notifyListeners();
      return;
    }
    testState = ZeroToHundredState.completed;
    final fuel = testFuel ?? PerformanceFuelType.gasoline;
    final record = PerformanceRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      vehicleId: vehicleId,
      date: DateTime.now(),
      fuel: fuel,
      zeroToSixtySeconds: zeroToSixtySeconds ?? 0,
      zeroToHundredSeconds: zeroToHundredSeconds ?? 0,
      peakGForce: math.max(peakResultantG, _peakResultantAtTestStart),
      peakLateralGForce: math.max(peakLateralG, _peakLateralAtTestStart),
      peakBrakingGForce: math.max(peakBrakingG, _peakBrakingAtTestStart),
      topSpeedKmh: maxSpeedKmh,
    );
    unawaited(_appendRecord(record));
    onTestFinished?.call(record, 'completed');
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Ciclo de vida: ligar/desligar sensores e GPS.
  // ---------------------------------------------------------------------

  /// Pede a permissão de localização (só enquanto o app estiver em uso) e
  /// liga os sensores e, se concedida, o GPS. Chamar ao abrir a tela.
  Future<void> start() async {
    await _loadCalibration();
    resetSessionPeaks();
    _startAccelSensors();
    // Autocalibração: assim que o celular ficar estável, calibra sozinho
    // com a última posição salva, sem precisar que o usuário aperte nada
    // (item B4 do Prompt 2). Se o carro já estiver em movimento, a
    // calibração simplesmente vai falhar após o tempo limite e o usuário
    // pode tentar de novo parado, pelo botão "Calibrar".
    unawaited(calibrate());
    gpsAvailable = await _ensureLocationPermission();
    if (gpsAvailable == true) {
      _startPositionStream(forceLocationManager: true);
    }
    notifyListeners();
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } on Object {
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Velocímetro: configurações de GPS por plataforma.
  // ---------------------------------------------------------------------

  LocationSettings _buildLocationSettings({required bool forceLocationManager}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Sem intervalDuration o Android usa um intervalo padrão bem maior
      // que 1 s, e o provedor "fundido" (fused) pode misturar GPS com rede
      // (bem mais lenta e imprecisa para velocidade). forceLocationManager
      // usa o GPS puro: a velocidade vem direto do efeito Doppler do sinal
      // do satélite, que é a leitura mais fresca disponível.
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 500),
        forceLocationManager: forceLocationManager,
      );
    }
    return AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      activityType: ActivityType.automotiveNavigation,
      distanceFilter: 0,
      pauseLocationUpdatesAutomatically: false,
    );
  }

  void _startPositionStream({required bool forceLocationManager}) {
    unawaited(_positionSubscription?.cancel());
    _positionFallbackTimer?.cancel();
    var gotFirstFix = false;
    final settings = _buildLocationSettings(forceLocationManager: forceLocationManager);
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        gotFirstFix = true;
        _handlePosition(position);
      },
      onError: (_) {
        gpsAvailable = false;
        notifyListeners();
      },
    );
    if (defaultTargetPlatform == TargetPlatform.android && forceLocationManager) {
      // Se o GPS puro (LocationManager) não responder em 12 s — alguns
      // aparelhos demoram muito ou não têm um chip GNSS dedicado acessível
      // assim — tenta de novo com o provedor fundido padrão do Android,
      // melhor que ficar sem nada.
      _positionFallbackTimer = Timer(const Duration(seconds: 12), () {
        if (!gotFirstFix) _startPositionStream(forceLocationManager: false);
      });
    }
  }

  void _handlePosition(Position position) {
    // Descarta amostras velhas (ex.: cache do provedor), para não atrasar
    // visualmente o velocímetro com uma leitura que já não é atual.
    final age = DateTime.now().difference(position.timestamp);
    if (age > const Duration(seconds: 3)) return;

    lastPositionAt = DateTime.now();
    lastPositionAccuracy = position.accuracy;
    lastSpeedAccuracy = position.speedAccuracy;

    final rawKmh = (position.speed * 3.6).clamp(0, 400).toDouble();
    if (rawKmh < 1) {
      // Abaixo de 1 km/h, mostra 0 direto, sem arrastar o filtro.
      speedKmh = 0;
    } else {
      final delta = (rawKmh - speedKmh).abs();
      // Filtro exponencial leve, sem janela: alfa maior quando a variação é
      // grande (resposta rápida), menor quando está estável (sem tremer).
      final alpha = delta > 3 ? 0.65 : 0.4;
      speedKmh = speedKmh + (rawKmh - speedKmh) * alpha;
    }
    if (speedKmh > maxSpeedKmh) maxSpeedKmh = speedKmh;

    // speedAccuracy == 0 significa "desconhecido" em alguns aparelhos, não
    // "perfeito"; só conta como sinal fraco quando for um valor real alto.
    final weakSpeedAccuracy = position.speedAccuracy != 0 && position.speedAccuracy > 3;
    final weakPositionAccuracy = position.accuracy > 30;
    gpsSignal = (weakSpeedAccuracy || weakPositionAccuracy) ? GpsSignal.weak : GpsSignal.ok;

    _onSpeedSample(speedKmh);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Força G: acelerômetro linear, com fallback para o bruto.
  // ---------------------------------------------------------------------

  void _startAccelSensors() {
    unawaited(_userAccelSubscription?.cancel());
    unawaited(_rawAccelFallbackSubscription?.cancel());
    _userAccelWatchdog?.cancel();
    usingLinearAccelSensor = true;
    var sawLinearEvent = false;
    _userAccelSubscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      (event) {
        sawLinearEvent = true;
        _userAccelWatchdog?.cancel();
        _onLinearAccel(_Vec3(event.x, event.y, event.z));
      },
      onError: (_) => _fallbackToRawAccel(),
    );
    // Sem nenhum evento do sensor linear em 2 s: cai para o bruto.
    _userAccelWatchdog = Timer(const Duration(seconds: 2), () {
      if (!sawLinearEvent) _fallbackToRawAccel();
    });
  }

  void _fallbackToRawAccel() {
    if (!usingLinearAccelSensor) return; // já caiu para o modo bruto
    usingLinearAccelSensor = false;
    _gravityEstimate = _Vec3.zero();
    unawaited(_userAccelSubscription?.cancel());
    _userAccelSubscription = null;
    _rawAccelFallbackSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      final raw = _Vec3(event.x, event.y, event.z);
      // Sem acelerômetro linear nativo: estima a gravidade com um filtro
      // passa-baixa forte (alfa 0,9 de peso para o valor antigo, bem mais
      // lento que o da Força G) e subtrai do valor bruto para chegar numa
      // aceleração linear aproximada.
      _gravityEstimate = _gravityEstimate * 0.9 + raw * 0.1;
      _onLinearAccel(raw - _gravityEstimate);
    });
    notifyListeners();
  }

  void _onLinearAccel(_Vec3 linear) {
    _filteredAccel = _filteredAccel + (linear - _filteredAccel) * _lowPassAlpha;
    resultantG = _filteredAccel.length / _gravityMs2;
    _trackAccelRate();

    final axes = _axes;
    if (axes != null) {
      longitudinalG = _filteredAccel.dot(axes.forward) / _gravityMs2;
      lateralG = _filteredAccel.dot(axes.right) / _gravityMs2;
      if (resultantG > peakResultantG) peakResultantG = resultantG;
      if (lateralG.abs() > peakLateralG) peakLateralG = lateralG.abs();
      if (-longitudinalG > peakBrakingG) peakBrakingG = -longitudinalG;
    } else {
      // Sem calibração válida ainda: mantém a bolinha centralizada (sem
      // direção), mas o módulo (resultantG) continua atualizando, para o
      // radar não parecer "morto" enquanto calibra.
      longitudinalG = 0;
      lateralG = 0;
    }
    notifyListeners();
  }

  void _trackAccelRate() {
    _accelSampleCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_accelRateWindowStart);
    if (elapsed.inMilliseconds >= 1000) {
      accelHz = _accelSampleCount * 1000 / elapsed.inMilliseconds;
      _accelSampleCount = 0;
      _accelRateWindowStart = now;
    }
  }

  /// Desliga sensores e GPS. Chamar ao sair da tela ou quando o app for
  /// para segundo plano.
  Future<void> stop() async {
    await _cancelCalibration();
    _userAccelWatchdog?.cancel();
    _userAccelWatchdog = null;
    _positionFallbackTimer?.cancel();
    _positionFallbackTimer = null;
    await _userAccelSubscription?.cancel();
    _userAccelSubscription = null;
    await _rawAccelFallbackSubscription?.cancel();
    _rawAccelFallbackSubscription = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Persistência local (mesmo padrão de outros serviços: arquivo JSON em
  // getApplicationDocumentsDirectory()/MyCarApp, gravação atômica).
  // ---------------------------------------------------------------------

  Future<Directory> _appDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _calibrationFile() async {
    final directory = await _appDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}performance_calibration.json',
    );
  }

  Future<File> _recordsFile() async {
    final directory = await _appDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}performance_records.json',
    );
  }

  Future<void> _loadCalibration() async {
    try {
      final file = await _calibrationFile();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final entry = json[vehicleId] as Map<String, dynamic>?;
      if (entry == null) return;
      final positionName = entry['position'] as String?;
      if (positionName != null) {
        phonePosition = PhonePosition.values.firstWhere(
          (item) => item.name == positionName,
          orElse: () => PhonePosition.uprightInHolder,
        );
      }
      final axesJson = entry['axes'] as Map<String, dynamic>?;
      if (axesJson != null) _axes = _CalibrationAxes.fromJson(axesJson);
    } on Object catch (error) {
      debugPrint('Calibração de desempenho corrompida; ignorando: $error');
    }
  }

  Future<void> _saveCalibration() async {
    try {
      final file = await _calibrationFile();
      final current = await file.exists()
          ? jsonDecode(await file.readAsString()) as Map<String, dynamic>
          : <String, dynamic>{};
      final axes = _axes;
      current[vehicleId] = {
        'position': phonePosition.name,
        if (axes != null) 'axes': axes.toJson(),
      };
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(current), flush: true);
      await temporary.rename(file.path);
    } on Object catch (error) {
      debugPrint('Não foi possível salvar a calibração de desempenho: $error');
    }
  }

  Future<List<PerformanceRecord>> loadRecords() async {
    try {
      final file = await _recordsFile();
      if (!await file.exists()) return const [];
      return PerformanceRecord.listFromJson(await file.readAsString())
          .where((item) => item.vehicleId == vehicleId)
          .toList();
    } on Object catch (error) {
      debugPrint('Recordes de desempenho corrompidos; ignorando: $error');
      return const [];
    }
  }

  Future<void> _appendRecord(PerformanceRecord record) async {
    try {
      final file = await _recordsFile();
      final records = await file.exists()
          ? PerformanceRecord.listFromJson(await file.readAsString())
          : <PerformanceRecord>[];
      records.add(record);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        PerformanceRecord.listToJson(records),
        flush: true,
      );
      await temporary.rename(file.path);
    } on Object catch (error) {
      debugPrint('Não foi possível salvar o recorde de desempenho: $error');
    }
  }
}
