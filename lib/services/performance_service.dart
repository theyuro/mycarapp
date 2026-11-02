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

/// Eixos de calibração de um veículo: o longitudinal (frente/trás) e o
/// lateral (esquerda/direita), ambos no referencial do acelerômetro do
/// celular montado no suporte.
class _CalibrationAxes {
  const _CalibrationAxes({required this.longitudinal, required this.lateral});

  final _Vec3 longitudinal;
  final _Vec3 lateral;

  Map<String, dynamic> toJson() => {
    'longitudinal': longitudinal.toJson(),
    'lateral': lateral.toJson(),
  };

  static _CalibrationAxes fromJson(Map<String, dynamic> json) =>
      _CalibrationAxes(
        longitudinal: _Vec3.fromJson(
          json['longitudinal'] as Map<String, dynamic>,
        ),
        lateral: _Vec3.fromJson(json['lateral'] as Map<String, dynamic>),
      );
}

/// Passo atual da calibração, para a tela mostrar a instrução certa.
enum CalibrationStep { idle, holdStill, accelerate, failed }

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
  StreamSubscription<Position>? _positionSubscription;

  _CalibrationAxes? _axes;
  _Vec3 _filteredAccel = _Vec3.zero();
  static const _lowPassAlpha = 0.25;

  bool get calibrated => _axes != null;

  // ---------------------------------------------------------------------
  // Velocímetro
  // ---------------------------------------------------------------------

  double speedKmh = 0;
  double maxSpeedKmh = 0;

  /// `null` enquanto não souber se a permissão foi concedida.
  bool? gpsAvailable;

  // ---------------------------------------------------------------------
  // Força G
  // ---------------------------------------------------------------------

  /// Positivo = aceleração para a frente; negativo = frenagem.
  double longitudinalG = 0;

  /// Positivo/negativo = direita/esquerda (só usado para o sinal exibido).
  double lateralG = 0;

  double get resultantG => math.sqrt(
    longitudinalG * longitudinalG + lateralG * lateralG,
  );

  double peakResultantG = 0;
  double peakLateralG = 0;
  double peakBrakingG = 0;

  // ---------------------------------------------------------------------
  // Calibração
  // ---------------------------------------------------------------------

  CalibrationStep calibrationStep = CalibrationStep.idle;

  /// Executa a calibração: 2 s com o celular parado (gravidade) e 2 s
  /// acelerando levemente para a frente (eixo longitudinal). Devolve se deu
  /// certo; quando falha, [calibrationStep] fica em [CalibrationStep.failed].
  Future<bool> calibrate() async {
    calibrationStep = CalibrationStep.holdStill;
    notifyListeners();
    final gravitySamples = <_Vec3>[];
    final gravitySubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) => gravitySamples.add(_Vec3(event.x, event.y, event.z)));
    await Future<void>.delayed(const Duration(seconds: 2));
    await gravitySubscription.cancel();
    if (gravitySamples.isEmpty) {
      calibrationStep = CalibrationStep.failed;
      notifyListeners();
      return false;
    }
    final gravity = gravitySamples
        .fold<_Vec3>(_Vec3.zero(), (sum, item) => sum + item)
        .normalized;

    calibrationStep = CalibrationStep.accelerate;
    notifyListeners();
    final forwardSamples = <_Vec3>[];
    final forwardSubscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) => forwardSamples.add(_Vec3(event.x, event.y, event.z)));
    await Future<void>.delayed(const Duration(seconds: 2));
    await forwardSubscription.cancel();
    if (forwardSamples.isEmpty) {
      calibrationStep = CalibrationStep.failed;
      notifyListeners();
      return false;
    }
    final forwardAverage = forwardSamples.fold<_Vec3>(
      _Vec3.zero(),
      (sum, item) => sum + item,
    ) * (1 / forwardSamples.length);
    // Remove a componente na vertical, para o eixo longitudinal ficar no
    // plano horizontal do carro.
    final longitudinal =
        (forwardAverage - gravity * forwardAverage.dot(gravity)).normalized;
    if (longitudinal.length < 0.5) {
      // Aceleração longitudinal fraca demais para definir o eixo com
      // confiança (celular quieto, ou movimento só vertical/lateral).
      calibrationStep = CalibrationStep.failed;
      notifyListeners();
      return false;
    }
    final lateral = gravity.cross(longitudinal).normalized;
    _axes = _CalibrationAxes(longitudinal: longitudinal, lateral: lateral);
    _filteredAccel = _Vec3.zero();
    resetSessionPeaks();
    calibrationStep = CalibrationStep.idle;
    await _saveCalibration();
    notifyListeners();
    return true;
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
    await _userAccelSubscription?.cancel();
    _userAccelSubscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onUserAccel);
    gpsAvailable = await _ensureLocationPermission();
    if (gpsAvailable == true) {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen(
        (position) {
          final kmh = (position.speed * 3.6).clamp(0, 400).toDouble();
          speedKmh = speedKmh + (kmh - speedKmh) * 0.4;
          if (speedKmh > maxSpeedKmh) maxSpeedKmh = speedKmh;
          _onSpeedSample(speedKmh);
          notifyListeners();
        },
        onError: (_) {
          gpsAvailable = false;
          notifyListeners();
        },
      );
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

  void _onUserAccel(UserAccelerometerEvent event) {
    final raw = _Vec3(event.x, event.y, event.z);
    _filteredAccel = _filteredAccel + (raw - _filteredAccel) * _lowPassAlpha;
    final axes = _axes;
    if (axes == null) {
      longitudinalG = 0;
      lateralG = 0;
      notifyListeners();
      return;
    }
    longitudinalG = _filteredAccel.dot(axes.longitudinal) / _gravityMs2;
    lateralG = _filteredAccel.dot(axes.lateral) / _gravityMs2;
    if (resultantG > peakResultantG) peakResultantG = resultantG;
    if (lateralG.abs() > peakLateralG) peakLateralG = lateralG.abs();
    if (-longitudinalG > peakBrakingG) peakBrakingG = -longitudinalG;
    notifyListeners();
  }

  /// Desliga sensores e GPS. Chamar ao sair da tela ou quando o app for
  /// para segundo plano.
  Future<void> stop() async {
    await _userAccelSubscription?.cancel();
    _userAccelSubscription = null;
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
      if (entry != null) _axes = _CalibrationAxes.fromJson(entry);
    } on Object catch (error) {
      debugPrint('Calibração de desempenho corrompida; ignorando: $error');
    }
  }

  Future<void> _saveCalibration() async {
    final axes = _axes;
    if (axes == null) return;
    try {
      final file = await _calibrationFile();
      final current = await file.exists()
          ? jsonDecode(await file.readAsString()) as Map<String, dynamic>
          : <String, dynamic>{};
      current[vehicleId] = axes.toJson();
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
