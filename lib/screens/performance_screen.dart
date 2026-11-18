import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/performance_record.dart';
import '../models/vehicle.dart';
import '../services/analytics_service.dart';
import '../services/performance_service.dart';
import '../l10n/l10n.dart';

/// Paleta própria da tela Desempenho (painel estilo "carro de corrida"),
/// sem usar AppColors: o fundo escuro pede contraste diferente do resto do
/// app.
class PerformanceColors {
  PerformanceColors._();

  static const background = Color(0xFF16191E);
  static const panel = Color(0xFF2B3038);
  static const radarLines = Color(0xFF6B7686);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFE3E8EF);
  static const gold = Color(0xFFD4A72C);
  static const goldLight = Color(0xFFFFE7A3);
  static const buttonOutline = Color(0xFF8FB4E8);
  static const onGold = Color(0xFF071B33);
}

const _disclaimerFileName = 'performance_disclaimer.json';

Future<bool> _hasAcceptedDisclaimer() async {
  try {
    final documents = await getApplicationDocumentsDirectory();
    final file = File(
      '${documents.path}${Platform.pathSeparator}MyCarApp${Platform.pathSeparator}$_disclaimerFileName',
    );
    if (!await file.exists()) return false;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return json['accepted'] == true;
  } on Object {
    return false;
  }
}

Future<void> _markDisclaimerAccepted() async {
  try {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}$_disclaimerFileName',
    );
    await file.writeAsString(jsonEncode({'accepted': true}), flush: true);
  } on Object {
    // Sem persistência: o diálogo volta a aparecer na próxima abertura.
  }
}

String fuelLabel(PerformanceFuelType fuel) => switch (fuel) {
  PerformanceFuelType.gasoline => tr.fuelGasoline,
  PerformanceFuelType.ethanol => tr.fuelEthanol,
  PerformanceFuelType.diesel => tr.fuelDiesel,
  PerformanceFuelType.naturalGas => tr.fuelNaturalGas,
  PerformanceFuelType.electric => tr.fuelElectric,
  PerformanceFuelType.flex => tr.fuelFlex,
  PerformanceFuelType.hybrid => tr.fuelHybrid,
};

// ---------------------------------------------------------------------
// Formatação numérica com vírgula decimal, como na maquete ("0,74 g",
// "112 km/h", "3,92 s").
// ---------------------------------------------------------------------

String formatG(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} g';
String formatSeconds(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} s';
String formatKmh(num value) => '${value.round()} km/h';

/// Estilo dos números grandes da tela (velocidade, força G, tempos,
/// recordes): Barlow Condensed 700 com algarismos tabulares, igual à
/// maquete (item 1 do Prompt 3). Cai na fonte padrão do app se o
/// BarlowCondensed não carregar (ver fonts: no pubspec.yaml).
TextStyle numberStyle(
  double size,
  Color color,
  double s, {
  FontWeight weight = FontWeight.w700,
  double height = 1.0,
}) => TextStyle(
  fontFamily: 'BarlowCondensed',
  fontSize: size * s,
  fontWeight: weight,
  color: color,
  height: height,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Estilo do texto comum (fonte padrão do app), com o fator de escala `s`.
TextStyle labelStyle(
  double size,
  Color color,
  double s, {
  FontWeight weight = FontWeight.w500,
  double? letterSpacing,
  double? height,
}) => TextStyle(
  fontSize: size * s,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing,
  height: height,
);

/// Fator de escala (item 2 do Prompt 3): multiplica tamanhos de fonte, dos
/// medidores e paddings, mantendo as larguras flexíveis (Expanded).
double performanceScale(Size screenSize, Orientation orientation) {
  if (orientation == Orientation.landscape) {
    return math.min(screenSize.width / 844, screenSize.height / 390).clamp(0.8, 1.4);
  }
  return (screenSize.width / 390).clamp(0.85, 1.3);
}

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen>
    with WidgetsBindingObserver {
  late final PerformanceService service = PerformanceService(
    vehicleId: widget.vehicle.id,
  );
  bool showingRecords = false;
  bool showDiagnostics = false;
  List<PerformanceRecord> records = const [];
  final List<Offset> _trail = [];

  /// Ponto (lateral, -longitudinal) em g no instante do pico da sessão,
  /// para marcar no radar (item 8 do Prompt 3). O serviço só guarda o
  /// módulo do pico, então a apresentação captura o vetor aqui, sem mexer
  /// na lógica de sensores.
  Offset? _peakPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    service.onTestFinished = _onTestFinished;
    service.addListener(_onServiceChanged);
    AnalyticsService.event('performance_open');
    unawaited(WakelockPlus.enable());
    // Permite paisagem só nesta tela; o app, fora dela, é só retrato.
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!await _hasAcceptedDisclaimer()) {
      if (!mounted) return;
      final accepted = await _showDisclaimerDialog();
      if (accepted != true) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await _markDisclaimerAccepted();
    }
    if (!mounted) return;
    await _showLocationExplainDialog();
    if (!mounted) return;
    await service.start();
    await _refreshRecords();
  }

  Future<void> _refreshRecords() async {
    final loaded = await service.loadRecords();
    if (mounted) setState(() => records = loaded);
  }

  void _onServiceChanged() {
    if (!mounted) return;
    if (service.calibrated) {
      final point = Offset(service.lateralG, -service.longitudinalG);
      _trail.add(point);
      if (_trail.length > 14) _trail.removeAt(0);
      // O pico acabou de ser atualizado neste ciclo: guarda o vetor, não só
      // o módulo, para desenhar a marca na posição certa do radar.
      if (service.resultantG >= service.peakResultantG) _peakPoint = point;
    }
    setState(() {});
  }

  void _onTestFinished(PerformanceRecord? record, String result) {
    AnalyticsService.event('performance_run', {'result': result});
    if (record != null) unawaited(_refreshRecords());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(service.start());
    } else {
      unawaited(service.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    service.removeListener(_onServiceChanged);
    service.dispose();
    unawaited(WakelockPlus.disable());
    // Remove o travamento de orientação desta tela: o resto do app não trava
    // a rotação em nenhum lugar, então a lista vazia volta ao padrão do
    // sistema em vez de forçar retrato.
    unawaited(SystemChrome.setPreferredOrientations([]));
    super.dispose();
  }

  Future<bool?> _showDisclaimerDialog() => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: PerformanceColors.gold),
      title: Text(tr.performanceDisclaimerTitle),
      content: Text(tr.performanceSafetyWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr.performanceDisclaimerAccept),
        ),
      ],
    ),
  );

  Future<void> _showLocationExplainDialog() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.location_on_outlined),
      title: Text(tr.performanceLocationTitle),
      content: Text(tr.performanceLocationExplain),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr.performanceLocationContinue),
        ),
      ],
    ),
  );

  Future<void> _calibrate() async {
    AnalyticsService.tap('performance_calibrate', screen: 'performance');
    final ok = await service.calibrate();
    if (!mounted) return;
    if (ok) {
      _trail.clear();
      _peakPoint = null;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? tr.performanceCalibrationDone : _calibrationFailureMessage(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mensagem específica para cada causa de falha na calibração (ver
  /// PerformanceService.calibrationFailure), em vez do antigo texto único
  /// "não foi possível calibrar" que não dizia o motivo.
  String _calibrationFailureMessage() => switch (service.calibrationFailure) {
    CalibrationFailureReason.noSensorData => tr.performanceNoAccelerometer,
    CalibrationFailureReason.positionMismatch => tr.performancePositionMismatch,
    CalibrationFailureReason.unstable => tr.performanceCalibratingHoldStill,
    CalibrationFailureReason.none => tr.performanceCalibrationFailed,
  };

  Future<void> _setPhonePosition(PhonePosition position) async {
    AnalyticsService.tap(
      'performance_phone_position',
      screen: 'performance',
      params: {'feature': position.name},
    );
    await service.setPhonePosition(position);
    if (!mounted) return;
    _trail.clear();
    _peakPoint = null;
  }

  /// Folha inferior aberta pelo botão "Calibrar" (item 10 do Prompt 3): o
  /// seletor de posição do celular saiu da tela principal e só aparece
  /// aqui, junto com o botão "Calibrar agora".
  Future<void> _openCalibrateSheet() async {
    final chosen = await showModalBottomSheet<PhonePosition>(
      context: context,
      showDragHandle: true,
      backgroundColor: PerformanceColors.panel,
      builder: (sheetContext) =>
          _CalibrateSheet(initialPosition: service.phonePosition),
    );
    if (chosen == null || !mounted) return;
    if (chosen == service.phonePosition) {
      await _calibrate();
    } else {
      await _setPhonePosition(chosen);
    }
  }

  Future<void> _armTest() async {
    if (service.gpsAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.performanceLocationDenied),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final fuel = await showModalBottomSheet<PerformanceFuelType>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _FuelPickerSheet(),
    );
    if (fuel == null || !mounted) return;
    AnalyticsService.tap(
      'performance_measure_start',
      screen: 'performance',
      params: {'feature': fuel.name},
    );
    service.armZeroToHundred(fuel);
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final screenSize = MediaQuery.sizeOf(context);
    final s = performanceScale(screenSize, orientation);
    final isLandscape = orientation == Orientation.landscape;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PerformanceColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _PerformanceHeader(
                vehicle: widget.vehicle,
                showingRecords: showingRecords,
                isLandscape: isLandscape,
                onToggleRecords: () =>
                    setState(() => showingRecords = !showingRecords),
                onToggleDiagnostics: () =>
                    setState(() => showDiagnostics = !showDiagnostics),
              ),
              if (showDiagnostics) _DiagnosticsBar(service: service),
              Expanded(
                child: showingRecords
                    ? _RecordsList(records: records, scale: s, isLandscape: isLandscape)
                    : SingleChildScrollView(
                        padding: isLandscape
                            ? EdgeInsets.symmetric(vertical: 10 * s, horizontal: 20 * s)
                            : EdgeInsets.all(20 * s),
                        child: isLandscape
                            ? _LandscapeBody(
                                service: service,
                                trail: _trail,
                                peakPoint: _peakPoint,
                                records: records,
                                scale: s,
                                onCalibrate: _openCalibrateSheet,
                                onMeasure: _armTest,
                              )
                            : _PortraitBody(
                                service: service,
                                trail: _trail,
                                peakPoint: _peakPoint,
                                records: records,
                                scale: s,
                                onCalibrate: _openCalibrateSheet,
                                onMeasure: _armTest,
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {}

class _FuelPickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
    children: [
      Text(
        tr.performanceSelectFuelTitle,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      for (final fuel in PerformanceFuelType.values)
        ListTile(
          title: Text(fuelLabel(fuel)),
          onTap: () => Navigator.pop(context, fuel),
        ),
    ],
  );
}

/// Folha inferior do botão "Calibrar" (item 10 do Prompt 3): escolhe a
/// posição do celular (salva por veículo) e dispara a calibração.
class _CalibrateSheet extends StatefulWidget {
  const _CalibrateSheet({required this.initialPosition});
  final PhonePosition initialPosition;

  @override
  State<_CalibrateSheet> createState() => _CalibrateSheetState();
}

class _CalibrateSheetState extends State<_CalibrateSheet> {
  late PhonePosition _selected = widget.initialPosition;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.performanceCalibrateButton,
          style: const TextStyle(
            color: PerformanceColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        SegmentedButton<PhonePosition>(
          segments: [
            ButtonSegment(
              value: PhonePosition.uprightInHolder,
              label: Text(tr.performancePositionUpright),
            ),
            ButtonSegment(
              value: PhonePosition.lyingFlat,
              label: Text(tr.performancePositionLyingFlat),
            ),
          ],
          selected: {_selected},
          onSelectionChanged: (selection) =>
              setState(() => _selected = selection.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: PerformanceColors.background,
            foregroundColor: PerformanceColors.textSecondary,
            selectedBackgroundColor: PerformanceColors.gold,
            selectedForegroundColor: PerformanceColors.onGold,
            side: const BorderSide(color: PerformanceColors.buttonOutline),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _selected),
            style: FilledButton.styleFrom(
              backgroundColor: PerformanceColors.gold,
              foregroundColor: PerformanceColors.onGold,
            ),
            child: Text(
              tr.performanceCalibrateNow,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PerformanceHeader extends StatelessWidget {
  const _PerformanceHeader({
    required this.vehicle,
    required this.showingRecords,
    required this.isLandscape,
    required this.onToggleRecords,
    required this.onToggleDiagnostics,
  });

  final Vehicle vehicle;
  final bool showingRecords;
  final bool isLandscape;
  final VoidCallback onToggleRecords;
  final VoidCallback onToggleDiagnostics;

  @override
  Widget build(BuildContext context) {
    final iconSize = isLandscape ? 32.0 : 36.0;
    final iconRadius = isLandscape ? 8.0 : 9.0;
    final titleSize = isLandscape ? 16.0 : 18.0;
    final gap = isLandscape ? 12.0 : 10.0;
    final buttonPaddingH = isLandscape ? 16.0 : 14.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(iconRadius),
            child: Image.asset(
              'assets/mycarapp_icon.png',
              width: iconSize,
              height: iconSize,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  // Toque longo liga/desliga o painel de diagnóstico (item
                  // B7 do Prompt 2), para conferir sensores em campo.
                  onLongPress: onToggleDiagnostics,
                  child: Text(
                    tr.performanceTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: PerformanceColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: titleSize,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  vehicle.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PerformanceColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: onToggleRecords,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: PerformanceColors.buttonOutline, width: 2),
                foregroundColor: PerformanceColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: buttonPaddingH),
              ),
              child: Text(
                showingRecords ? tr.performanceBack : tr.performanceRecords,
                style: const TextStyle(
                  color: PerformanceColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              color: PerformanceColors.gold,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: Text(
              tr.performancePremiumBadge,
              style: const TextStyle(
                color: PerformanceColors.onGold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.96,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de diagnóstico ligada/desligada por um toque longo no título da
/// tela (item B7 do Prompt 2; posição abaixo do cabeçalho conforme item 10
/// do Prompt 3): sensor em uso, taxa de leituras, situação da calibração e
/// idade/precisão da última posição do GPS, para o Yuri conferir em campo
/// sem depender de adivinhação. Não participa do fator de escala `s`: é um
/// recurso de depuração, não da maquete.
class _DiagnosticsBar extends StatelessWidget {
  const _DiagnosticsBar({required this.service});
  final PerformanceService service;

  @override
  Widget build(BuildContext context) {
    final sensorText = service.usingLinearAccelSensor
        ? tr.performanceDiagnosticsSensorLinear
        : tr.performanceDiagnosticsSensorRaw;
    final calibrationText = service.calibrated
        ? tr.performanceDiagnosticsCalibrated
        : tr.performanceDiagnosticsNotCalibrated;
    final lastPositionAt = service.lastPositionAt;
    final gpsAgeText = lastPositionAt == null
        ? tr.performanceDiagnosticsNoGpsFix
        : '${(DateTime.now().difference(lastPositionAt).inMilliseconds / 1000).toStringAsFixed(1)}s';
    final accuracyText = service.lastPositionAccuracy == null
        ? '--'
        : '${service.lastPositionAccuracy!.toStringAsFixed(1)}m';
    final speedAccuracyText = service.lastSpeedAccuracy == null
        ? '--'
        : '${service.lastSpeedAccuracy!.toStringAsFixed(1)}m/s';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Text(
        '$sensorText · ${service.accelHz.toStringAsFixed(0)} Hz · '
        '$calibrationText · GPS: $gpsAgeText · ±$accuracyText · ±$speedAccuracyText',
        style: const TextStyle(
          color: PerformanceColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Corpo da tela, retrato e paisagem (seções 5 e 6 do Prompt 3).
// ---------------------------------------------------------------------

class _PortraitBody extends StatelessWidget {
  const _PortraitBody({
    required this.service,
    required this.trail,
    required this.peakPoint,
    required this.records,
    required this.scale,
    required this.onCalibrate,
    required this.onMeasure,
  });

  final PerformanceService service;
  final List<Offset> trail;
  final Offset? peakPoint;
  final List<PerformanceRecord> records;
  final double scale;
  final VoidCallback onCalibrate;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final lateralDirection = service.lateralG > 0.05
        ? tr.performanceDirectionRight
        : service.lateralG < -0.05
        ? tr.performanceDirectionLeft
        : '--';
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SpeedometerPanel(service: service, scale: s, isLandscape: false),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: _GForcePanel(
                  service: service,
                  trail: trail,
                  peakPoint: peakPoint,
                  scale: s,
                  isLandscape: false,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * s),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: tr.performanceLateral,
                value: formatG(service.lateralG.abs()),
                legend: lateralDirection,
                scale: s,
              ),
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: _StatCard(
                label: tr.performanceAcceleration,
                value: formatG(service.longitudinalG),
                legend: tr.performanceLegendForward,
                scale: s,
              ),
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: _StatCard(
                label: tr.performanceSessionPeak,
                value: formatG(service.peakResultantG),
                legend: lateralDirection,
                scale: s,
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * s),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: tr.performanceZeroToSixty,
                value: service.zeroToSixtySeconds == null
                    ? '--'
                    : formatSeconds(service.zeroToSixtySeconds!),
                scale: s,
              ),
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: _StatCard(
                label: tr.performanceSixtyToHundred,
                value: service.zeroToHundredSeconds == null
                    ? '--'
                    : formatSeconds(service.zeroToHundredSeconds!),
                scale: s,
              ),
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: _GpsStatusCard(service: service, scale: s),
            ),
          ],
        ),
        SizedBox(height: 10 * s),
        _ByFuelCard(records: records, scale: s),
        SizedBox(height: 18 * s),
        _TestButtons(service: service, onCalibrate: onCalibrate, onMeasure: onMeasure, scale: s),
        SizedBox(height: 14 * s),
        _SafetyNotice(scale: s),
      ],
    );
  }
}

class _LandscapeBody extends StatelessWidget {
  const _LandscapeBody({
    required this.service,
    required this.trail,
    required this.peakPoint,
    required this.records,
    required this.scale,
    required this.onCalibrate,
    required this.onMeasure,
  });

  final PerformanceService service;
  final List<Offset> trail;
  final Offset? peakPoint;
  final List<PerformanceRecord> records;
  final double scale;
  final VoidCallback onCalibrate;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final byFuel = <PerformanceFuelType, double>{};
    for (final record in records) {
      final current = byFuel[record.fuel];
      if (current == null || record.zeroToHundredSeconds < current) {
        byFuel[record.fuel] = record.zeroToHundredSeconds;
      }
    }
    String bestFor(PerformanceFuelType fuel) =>
        byFuel[fuel] == null ? '--' : formatSeconds(byFuel[fuel]!);
    final lateralDirection = service.lateralG > 0.05
        ? tr.performanceDirectionRight
        : service.lateralG < -0.05
        ? tr.performanceDirectionLeft
        : '--';
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SpeedometerPanel(service: service, scale: s, isLandscape: true),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: _GForcePanel(
                  service: service,
                  trail: trail,
                  peakPoint: peakPoint,
                  scale: s,
                  isLandscape: true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8 * s),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '${tr.performanceLateral} · $lateralDirection',
                value: formatG(service.lateralG.abs()),
                scale: s,
                compact: true,
              ),
            ),
            SizedBox(width: 8 * s),
            Expanded(
              child: _StatCard(
                label: tr.performanceAcceleration,
                value: formatG(service.longitudinalG),
                scale: s,
                compact: true,
              ),
            ),
            SizedBox(width: 8 * s),
            Expanded(
              child: _StatCard(
                label: tr.performanceSessionPeak,
                value: formatG(service.peakResultantG),
                scale: s,
                compact: true,
              ),
            ),
            SizedBox(width: 8 * s),
            Expanded(
              child: _StatCard(
                label: tr.performanceZeroToSixty,
                value: service.zeroToSixtySeconds == null
                    ? '--'
                    : formatSeconds(service.zeroToSixtySeconds!),
                scale: s,
                compact: true,
              ),
            ),
            SizedBox(width: 8 * s),
            Expanded(
              child: _StatCard(
                label: '0–100 ${fuelLabel(PerformanceFuelType.gasoline)}',
                value: bestFor(PerformanceFuelType.gasoline),
                scale: s,
                compact: true,
              ),
            ),
            SizedBox(width: 8 * s),
            Expanded(
              child: _StatCard(
                label: '0–100 ${fuelLabel(PerformanceFuelType.ethanol)}',
                value: bestFor(PerformanceFuelType.ethanol),
                scale: s,
                compact: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 130 * s,
              height: 46 * s,
              child: OutlinedButton(
                onPressed: onCalibrate,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: PerformanceColors.buttonOutline, width: 2),
                  foregroundColor: PerformanceColors.buttonOutline,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * s),
                  ),
                ),
                child: Text(
                  tr.performanceCalibrateButton,
                  style: labelStyle(14, PerformanceColors.buttonOutline, s, weight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(width: 10 * s),
            SizedBox(
              width: 190 * s,
              height: 46 * s,
              child: FilledButton(
                onPressed: service.testState == ZeroToHundredState.measuring ? null : onMeasure,
                style: FilledButton.styleFrom(
                  backgroundColor: PerformanceColors.gold,
                  foregroundColor: PerformanceColors.onGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * s),
                  ),
                ),
                child: Text(
                  tr.performanceMeasureButton,
                  style: labelStyle(14, PerformanceColors.onGold, s, weight: FontWeight.w700, letterSpacing: 0.56),
                ),
              ),
            ),
            SizedBox(width: 10 * s),
            Expanded(child: _SafetyNotice(scale: s, compact: true)),
          ],
        ),
      ],
    );
  }
}

Widget _panelTitle(String text, double s) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('● ', style: TextStyle(color: PerformanceColors.gold, fontSize: 12 * s)),
    Text(
      text,
      style: labelStyle(12, PerformanceColors.textSecondary, s, letterSpacing: 0.96),
    ),
  ],
);

class _SpeedometerPanel extends StatelessWidget {
  const _SpeedometerPanel({
    required this.service,
    required this.scale,
    required this.isLandscape,
  });

  final PerformanceService service;
  final double scale;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final displayText =
        service.gpsAvailable == false ? '--' : service.speedKmh.round().toString();
    final gaugeWidth = (isLandscape ? 170.0 : 156.0) * s;
    // Na paisagem o medidor é recortado na faixa útil do viewBox (y 36–150,
    // ~115 de altura) para caber no painel de altura fixa 164.
    final gaugeHeight = isLandscape ? gaugeWidth * (114 / 168) : gaugeWidth;
    final gauge = ClipRect(
      child: SizedBox(
        width: gaugeWidth,
        height: gaugeHeight,
        child: CustomPaint(
          painter: _SpeedometerPainter(
            speedKmh: service.speedKmh,
            displayText: displayText,
            cropTop: isLandscape ? 36 : 0,
          ),
        ),
      ),
    );
    final maxSpeedText = Text(formatKmh(service.maxSpeedKmh), style: numberStyle(isLandscape ? 44 : 34, PerformanceColors.gold, s));
    final legend = Text(tr.performanceSessionMax, style: labelStyle(12, PerformanceColors.goldLight, s));
    final gpsNote = service.gpsAvailable != true
        ? Padding(
            padding: EdgeInsets.only(top: 2 * s),
            child: Text(
              service.gpsAvailable == null
                  ? tr.performanceGpsSearching
                  : tr.performanceSpeedUnavailable,
              textAlign: TextAlign.center,
              style: labelStyle(11, PerformanceColors.textSecondary, s, weight: FontWeight.w600),
            ),
          )
        : const SizedBox.shrink();

    if (isLandscape) {
      return Container(
        height: 164 * s,
        padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 14 * s),
        decoration: BoxDecoration(
          color: PerformanceColors.panel,
          borderRadius: BorderRadius.circular(16 * s),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            gauge,
            SizedBox(width: 16 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _panelTitle(tr.performanceSpeedometerTitle, s),
                  SizedBox(height: 2 * s),
                  FittedBox(fit: BoxFit.scaleDown, child: maxSpeedText),
                  legend,
                  gpsNote,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(10 * s, 12 * s, 10 * s, 14 * s),
      decoration: BoxDecoration(
        color: PerformanceColors.panel,
        borderRadius: BorderRadius.circular(18 * s),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _panelTitle(tr.performanceSpeedometerTitle, s),
          SizedBox(height: 4 * s),
          gauge,
          gpsNote,
          SizedBox(height: 4 * s),
          FittedBox(fit: BoxFit.scaleDown, child: maxSpeedText),
          SizedBox(height: 4 * s),
          legend,
        ],
      ),
    );
  }
}

/// Desenha o velocímetro num viewBox fixo de 168×168 (item 7 do Prompt 3) e
/// escala pelo tamanho real do widget. Na paisagem, só a faixa útil
/// (y 36–150) é visível: o widget já vem recortado por um [ClipRect] por
/// fora, e aqui só deslocamos o desenho para cima.
class _SpeedometerPainter extends CustomPainter {
  _SpeedometerPainter({
    required this.speedKmh,
    required this.displayText,
    required this.cropTop,
  });

  final double speedKmh;
  final String displayText;
  final double cropTop;

  static const _viewBox = 168.0;
  static const _center = Offset(84, 110);
  static const _radius = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(0, -cropTop);

    final maxSpeed = speedKmh > 150 ? 240.0 : 160.0;
    final progress = (speedKmh / maxSpeed).clamp(0.0, 1.0);
    final rect = Rect.fromCircle(center: _center, radius: _radius);

    final track = Paint()
      ..color = PerformanceColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, track);

    final fill = Paint()
      ..color = PerformanceColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi * progress, false, fill);

    _drawText(
      canvas,
      displayText,
      const Offset(84, 104),
      const TextStyle(
        fontFamily: 'BarlowCondensed',
        fontSize: 46,
        fontWeight: FontWeight.w700,
        color: PerformanceColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
    _drawText(
      canvas,
      'km/h',
      const Offset(84, 124),
      const TextStyle(fontSize: 14, color: PerformanceColors.textSecondary, fontWeight: FontWeight.w500),
    );
    _drawText(
      canvas,
      '0',
      const Offset(20, 142),
      const TextStyle(fontSize: 13, color: PerformanceColors.textSecondary, fontWeight: FontWeight.w500),
    );
    _drawText(
      canvas,
      maxSpeed.round().toString(),
      const Offset(148, 142),
      const TextStyle(fontSize: 13, color: PerformanceColors.textSecondary, fontWeight: FontWeight.w500),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) =>
      oldDelegate.speedKmh != speedKmh || oldDelegate.displayText != displayText;
}

void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

class _GForcePanel extends StatelessWidget {
  const _GForcePanel({
    required this.service,
    required this.trail,
    required this.peakPoint,
    required this.scale,
    required this.isLandscape,
  });

  final PerformanceService service;
  final List<Offset> trail;
  final Offset? peakPoint;
  final double scale;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final gaugeSize = (isLandscape ? 148.0 : 156.0) * s;
    final gauge = SizedBox(
      width: gaugeSize,
      height: gaugeSize,
      child: CustomPaint(
        painter: _GForceRadarPainter(
          point: Offset(service.lateralG, -service.longitudinalG),
          peakPoint: peakPoint,
          trail: trail,
        ),
      ),
    );
    // Enquanto não houver calibração válida, o radar não fica "morto": o
    // módulo (resultantG) continua atualizando e o texto muda conforme o
    // estado (item B6 do Prompt 2).
    final valueText = service.calibrated
        ? formatG(service.resultantG)
        : switch (service.calibrationStep) {
            CalibrationStep.waiting => tr.performanceCalibratingShort,
            _ => tr.performanceCalibrateNeeded,
          };
    final legendText = service.calibrated ? tr.performanceGForceResultant : '';
    final valueStyle = service.calibrated
        ? numberStyle(isLandscape ? 52 : 34, PerformanceColors.textPrimary, s)
        : labelStyle(isLandscape ? 16 : 13, PerformanceColors.textSecondary, s, weight: FontWeight.w600);

    if (isLandscape) {
      return Container(
        height: 164 * s,
        padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 14 * s),
        decoration: BoxDecoration(
          color: PerformanceColors.panel,
          borderRadius: BorderRadius.circular(16 * s),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            gauge,
            SizedBox(width: 16 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _panelTitle(tr.performanceGForceTitle, s),
                  SizedBox(height: 2 * s),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(valueText, style: valueStyle)),
                  if (legendText.isNotEmpty)
                    Text(legendText, style: labelStyle(12, PerformanceColors.goldLight, s)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(10 * s, 12 * s, 10 * s, 14 * s),
      decoration: BoxDecoration(
        color: PerformanceColors.panel,
        borderRadius: BorderRadius.circular(18 * s),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _panelTitle(tr.performanceGForceTitle, s),
          SizedBox(height: 4 * s),
          gauge,
          SizedBox(height: 4 * s),
          FittedBox(fit: BoxFit.scaleDown, child: Text(valueText, style: valueStyle)),
          if (legendText.isNotEmpty) ...[
            SizedBox(height: 4 * s),
            Text(legendText, style: labelStyle(12, PerformanceColors.goldLight, s)),
          ],
        ],
      ),
    );
  }
}

/// Desenha o radar da Força G num viewBox fixo de 300×300 (item 8 do
/// Prompt 3), escalado pelo tamanho real do widget.
class _GForceRadarPainter extends CustomPainter {
  _GForceRadarPainter({
    required this.point,
    required this.peakPoint,
    required this.trail,
  });

  final Offset point;
  final Offset? peakPoint;
  final List<Offset> trail;

  static const _viewBox = 300.0;
  static const _center = Offset(150, 150);
  static const _pxPerG = 80.0; // 40 px (viewBox) = 0,5 g
  static const _maxRadius = 120.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;
    canvas.save();
    canvas.scale(scale);

    final fillPaint = Paint()
      ..color = PerformanceColors.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(_center, _maxRadius, fillPaint);
    final borderPaint = Paint()
      ..color = PerformanceColors.radarLines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(_center, _maxRadius, borderPaint);

    final ringPaint = Paint()
      ..color = PerformanceColors.radarLines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(_center, 80, ringPaint);
    canvas.drawCircle(_center, 40, ringPaint);

    final crossPaint = Paint()
      ..color = PerformanceColors.radarLines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(const Offset(30, 150), const Offset(270, 150), crossPaint);
    canvas.drawLine(const Offset(150, 30), const Offset(150, 270), crossPaint);

    const labelStyle = TextStyle(
      fontSize: 22,
      color: PerformanceColors.textSecondary,
      fontWeight: FontWeight.w500,
    );
    _drawText(canvas, tr.performanceAccelShort, const Offset(150, 22), labelStyle);
    _drawText(canvas, tr.performanceBrakeShort, const Offset(150, 294), labelStyle);

    Offset toCanvas(Offset g) {
      var v = Offset(g.dx * _pxPerG, g.dy * _pxPerG);
      if (v.distance > _maxRadius) v = v * (_maxRadius / v.distance);
      return _center + v;
    }

    if (trail.isNotEmpty) {
      final trailPaint = Paint()
        ..color = PerformanceColors.gold.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(_center.dx, _center.dy);
      for (final g in trail) {
        final p = toCanvas(g);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, trailPaint);
    }

    final peak = peakPoint;
    if (peak != null) {
      final peakPaint = Paint()
        ..color = PerformanceColors.goldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      _drawDashedCircle(canvas, toCanvas(peak), 9, peakPaint);
    }

    final dotCenter = toCanvas(point);
    canvas.drawCircle(dotCenter, 16, Paint()..color = PerformanceColors.gold);
    canvas.drawCircle(dotCenter, 6, Paint()..color = PerformanceColors.background);

    canvas.restore();
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 4.0;
    final circumference = 2 * math.pi * radius;
    final dashCount = math.max(4, (circumference / (dashLength + gapLength)).round());
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      final sweep = (dashLength / (dashLength + gapLength)) * (2 * math.pi / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GForceRadarPainter oldDelegate) => true;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.scale,
    this.legend,
    this.compact = false,
  });

  final String label;
  final String value;
  final double scale;
  final String? legend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.all(compact ? 10 * s : 12 * s),
      decoration: BoxDecoration(
        color: PerformanceColors.panel,
        borderRadius: BorderRadius.circular(compact ? 12 * s : 14 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: labelStyle(12, PerformanceColors.textSecondary, s),
          ),
          SizedBox(height: 2 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: numberStyle(compact ? 28 : 30, PerformanceColors.textPrimary, s, height: 1.1),
            ),
          ),
          if (legend != null) ...[
            SizedBox(height: 2 * s),
            Text(legend!, style: labelStyle(12, PerformanceColors.goldLight, s)),
          ],
        ],
      ),
    );
  }
}

class _GpsStatusCard extends StatelessWidget {
  const _GpsStatusCard({required this.service, required this.scale});
  final PerformanceService service;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    // "Buscando GPS…" até a primeira posição; "Sinal fraco"/"Sinal forte"
    // conforme a precisão reportada (estes textos substituem os do Prompt
    // 2, ver item 5 do Prompt 3).
    final statusText = service.gpsAvailable == false
        ? tr.performanceGpsDenied
        : service.gpsAvailable == null || service.lastPositionAt == null
        ? tr.performanceGpsSearching
        : service.gpsSignal == GpsSignal.weak
        ? tr.performanceGpsWeak
        : tr.performanceGpsOk;
    return Container(
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: PerformanceColors.panel,
        borderRadius: BorderRadius.circular(14 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr.performanceGpsStatus, style: labelStyle(12, PerformanceColors.textSecondary, s)),
          SizedBox(height: 2 * s),
          Text(
            statusText,
            maxLines: 2,
            style: labelStyle(14, PerformanceColors.goldLight, s, weight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ByFuelCard extends StatelessWidget {
  const _ByFuelCard({required this.records, required this.scale});
  final List<PerformanceRecord> records;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final byFuel = <PerformanceFuelType, double>{};
    for (final record in records) {
      final current = byFuel[record.fuel];
      if (current == null || record.zeroToHundredSeconds < current) {
        byFuel[record.fuel] = record.zeroToHundredSeconds;
      }
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12 * s, horizontal: 16 * s),
      decoration: BoxDecoration(
        color: PerformanceColors.panel,
        borderRadius: BorderRadius.circular(14 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr.performanceByFuelTitle,
            style: labelStyle(13, PerformanceColors.textPrimary, s, weight: FontWeight.w600),
          ),
          SizedBox(height: 6 * s),
          if (byFuel.isEmpty)
            Text(
              tr.performanceByFuelEmpty,
              style: labelStyle(12, PerformanceColors.textSecondary, s),
            )
          else
            for (final entry in byFuel.entries)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 3 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fuelLabel(entry.key),
                        style: labelStyle(13, PerformanceColors.textSecondary, s),
                      ),
                    ),
                    Text(
                      formatSeconds(entry.value),
                      style: labelStyle(13, PerformanceColors.textPrimary, s, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TestButtons extends StatelessWidget {
  const _TestButtons({
    required this.service,
    required this.onCalibrate,
    required this.onMeasure,
    required this.scale,
  });

  final PerformanceService service;
  final VoidCallback onCalibrate;
  final VoidCallback onMeasure;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final statusText = switch (service.testState) {
      ZeroToHundredState.armed => tr.performanceArmed,
      ZeroToHundredState.measuring => tr.performanceMeasuring,
      ZeroToHundredState.completed => tr.performanceCompleted,
      ZeroToHundredState.cancelled => tr.performanceCancelled,
      ZeroToHundredState.idle => null,
    };
    // Calibração em um único passo (sem a antiga etapa de "acelerar para a
    // frente"): "waiting" é tanto a espera normal quanto, ao desistir após
    // 10 s por instabilidade, a mesma mensagem de "segure o celular parado".
    final calibrationText = switch (service.calibrationStep) {
      CalibrationStep.waiting => tr.performanceCalibratingHoldStill,
      CalibrationStep.failed => switch (service.calibrationFailure) {
        CalibrationFailureReason.noSensorData => tr.performanceNoAccelerometer,
        CalibrationFailureReason.positionMismatch => tr.performancePositionMismatch,
        CalibrationFailureReason.unstable => tr.performanceCalibratingHoldStill,
        CalibrationFailureReason.none => tr.performanceCalibrationFailed,
      },
      CalibrationStep.idle => null,
    };
    final busy = service.testState == ZeroToHundredState.measuring ||
        service.calibrationStep == CalibrationStep.waiting;
    return Column(
      children: [
        if (calibrationText != null) ...[
          Text(
            calibrationText,
            textAlign: TextAlign.center,
            style: labelStyle(13, PerformanceColors.goldLight, s, weight: FontWeight.w600),
          ),
          SizedBox(height: 8 * s),
        ],
        if (statusText != null) ...[
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: labelStyle(13, PerformanceColors.goldLight, s, weight: FontWeight.w600),
          ),
          SizedBox(height: 8 * s),
        ],
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 48 * s,
                child: OutlinedButton(
                  onPressed: busy ? null : onCalibrate,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PerformanceColors.buttonOutline, width: 2),
                    foregroundColor: PerformanceColors.buttonOutline,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * s)),
                  ),
                  child: Text(
                    tr.performanceCalibrateButton,
                    style: labelStyle(14, PerformanceColors.buttonOutline, s, weight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10 * s),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48 * s,
                child: FilledButton(
                  onPressed: busy ? null : onMeasure,
                  style: FilledButton.styleFrom(
                    backgroundColor: PerformanceColors.gold,
                    foregroundColor: PerformanceColors.onGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * s)),
                  ),
                  child: Text(
                    tr.performanceMeasureButton,
                    style: labelStyle(14, PerformanceColors.onGold, s, weight: FontWeight.w700, letterSpacing: 0.56),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (service.testState == ZeroToHundredState.armed ||
            service.testState == ZeroToHundredState.measuring)
          Padding(
            padding: EdgeInsets.only(top: 8 * s),
            child: TextButton(
              onPressed: service.cancelZeroToHundred,
              child: Text(
                tr.performanceCancelButton,
                style: labelStyle(13, PerformanceColors.textSecondary, s),
              ),
            ),
          ),
      ],
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice({required this.scale, this.compact = false});
  final double scale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: compact
          ? EdgeInsets.symmetric(vertical: 6 * s, horizontal: 12 * s)
          : EdgeInsets.symmetric(vertical: 10 * s, horizontal: 12 * s),
      decoration: BoxDecoration(
        color: PerformanceColors.panel,
        borderRadius: BorderRadius.circular(compact ? 10 * s : 12 * s),
        border: Border.all(color: PerformanceColors.gold, width: 1),
      ),
      child: Row(
        crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: PerformanceColors.gold,
            size: (compact ? 16 : 18) * s,
          ),
          SizedBox(width: (compact ? 8 : 10) * s),
          Expanded(
            child: Text(
              tr.performanceSafetyWarning,
              maxLines: compact ? 1 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: labelStyle(
                compact ? 12 : 12.5,
                PerformanceColors.goldLight,
                s,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsList extends StatelessWidget {
  const _RecordsList({required this.records, required this.scale, required this.isLandscape});
  final List<PerformanceRecord> records;
  final double scale;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24 * s),
          child: Text(
            tr.performanceRecordsEmpty,
            textAlign: TextAlign.center,
            style: labelStyle(14, PerformanceColors.textSecondary, s),
          ),
        ),
      );
    }
    final byFuel = <PerformanceFuelType, PerformanceRecord>{};
    for (final record in records) {
      final current = byFuel[record.fuel];
      if (current == null ||
          record.zeroToHundredSeconds < current.zeroToHundredSeconds) {
        byFuel[record.fuel] = record;
      }
    }
    final bestLateral = records.reduce(
      (a, b) => a.peakLateralGForce >= b.peakLateralGForce ? a : b,
    );
    final bestBraking = records.reduce(
      (a, b) => a.peakBrakingGForce >= b.peakBrakingGForce ? a : b,
    );
    final bestSpeed = records.reduce(
      (a, b) => a.topSpeedKmh >= b.topSpeedKmh ? a : b,
    );
    final tiles = [
      for (final entry in byFuel.entries)
        _RecordTile(
          title: tr.performanceRecordBest0to100,
          detail: '${fuelLabel(entry.key)} · ${formatDate(entry.value.date)}',
          value: formatSeconds(entry.value.zeroToHundredSeconds),
          scale: s,
          valueSize: isLandscape ? 30 : 28,
        ),
      _RecordTile(
        title: tr.performanceRecordBestLateral,
        detail: formatDate(bestLateral.date),
        value: formatG(bestLateral.peakLateralGForce),
        scale: s,
        valueSize: isLandscape ? 30 : 28,
      ),
      _RecordTile(
        title: tr.performanceRecordBestBraking,
        detail: formatDate(bestBraking.date),
        value: formatG(bestBraking.peakBrakingGForce),
        scale: s,
        valueSize: isLandscape ? 30 : 28,
      ),
      _RecordTile(
        title: tr.performanceRecordTopSpeed,
        detail: formatDate(bestSpeed.date),
        value: formatKmh(bestSpeed.topSpeedKmh),
        scale: s,
        valueSize: isLandscape ? 30 : 28,
      ),
    ];
    final safety = Padding(
      padding: EdgeInsets.only(top: 14 * s),
      child: _SafetyNotice(scale: s, compact: isLandscape),
    );
    if (isLandscape) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 20 * s),
        child: Column(
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10 * s,
                crossAxisSpacing: 10 * s,
                mainAxisExtent: 72 * s,
              ),
              children: tiles,
            ),
            safety,
          ],
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.all(20 * s),
      children: [
        for (final tile in tiles)
          Padding(padding: EdgeInsets.only(bottom: 10 * s), child: tile),
        safety,
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.title,
    required this.detail,
    required this.value,
    required this.scale,
    required this.valueSize,
  });

  final String title;
  final String detail;
  final String value;
  final double scale;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14 * s, horizontal: 16 * s),
      decoration: BoxDecoration(
        color: PerformanceColors.panel,
        borderRadius: BorderRadius.circular(14 * s),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: labelStyle(13, PerformanceColors.textPrimary, s, weight: FontWeight.w600),
                ),
                SizedBox(height: 2 * s),
                Text(
                  detail,
                  style: labelStyle(12, PerformanceColors.textSecondary, s),
                ),
              ],
            ),
          ),
          SizedBox(width: 14 * s),
          Text(value, style: numberStyle(valueSize, PerformanceColors.gold, s)),
        ],
      ),
    );
  }
}
