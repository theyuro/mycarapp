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
  List<PerformanceRecord> records = const [];
  final List<Offset> _trail = [];

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
      _trail.add(Offset(service.lateralG, -service.longitudinalG));
      if (_trail.length > 14) _trail.removeAt(0);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? tr.performanceCalibrationDone : tr.performanceCalibrationFailed,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    return Scaffold(
      backgroundColor: PerformanceColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _PerformanceHeader(
              vehicle: widget.vehicle,
              showingRecords: showingRecords,
              onToggleRecords: () =>
                  setState(() => showingRecords = !showingRecords),
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: showingRecords
                  ? _RecordsList(records: records)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: orientation == Orientation.landscape
                          ? _LandscapeBody(
                              service: service,
                              trail: _trail,
                              records: records,
                              onCalibrate: _calibrate,
                              onMeasure: _armTest,
                            )
                          : _PortraitBody(
                              service: service,
                              trail: _trail,
                              records: records,
                              onCalibrate: _calibrate,
                              onMeasure: _armTest,
                            ),
                    ),
            ),
          ],
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

class _PerformanceHeader extends StatelessWidget {
  const _PerformanceHeader({
    required this.vehicle,
    required this.showingRecords,
    required this.onToggleRecords,
    required this.onBack,
  });

  final Vehicle vehicle;
  final bool showingRecords;
  final VoidCallback onToggleRecords;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: PerformanceColors.textPrimary),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/mycarapp_icon.png',
            width: 30,
            height: 30,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Desempenho',
                style: TextStyle(
                  color: PerformanceColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: PerformanceColors.gold,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tr.performancePremiumBadge,
            style: const TextStyle(
              color: PerformanceColors.onGold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onToggleRecords,
          child: Text(
            showingRecords ? tr.performanceBack : tr.performanceRecords,
            style: const TextStyle(
              color: PerformanceColors.goldLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PortraitBody extends StatelessWidget {
  const _PortraitBody({
    required this.service,
    required this.trail,
    required this.records,
    required this.onCalibrate,
    required this.onMeasure,
  });

  final PerformanceService service;
  final List<Offset> trail;
  final List<PerformanceRecord> records;
  final VoidCallback onCalibrate;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _SpeedometerPanel(service: service)),
            const SizedBox(width: 10),
            Expanded(child: _GForcePanel(service: service, trail: trail)),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _StatsGrid(service: service),
      const SizedBox(height: 14),
      _ByFuelCard(records: records),
      const SizedBox(height: 18),
      _TestControls(service: service, onCalibrate: onCalibrate, onMeasure: onMeasure),
      const SizedBox(height: 14),
      const _SafetyNotice(),
    ],
  );
}

class _LandscapeBody extends StatelessWidget {
  const _LandscapeBody({
    required this.service,
    required this.trail,
    required this.records,
    required this.onCalibrate,
    required this.onMeasure,
  });

  final PerformanceService service;
  final List<Offset> trail;
  final List<PerformanceRecord> records;
  final VoidCallback onCalibrate;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _SpeedometerPanel(service: service)),
            const SizedBox(width: 10),
            Expanded(child: _GForcePanel(service: service, trail: trail)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _StatsGrid(service: service, columns: 6, byFuelInline: records),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TestControls(
              service: service,
              onCalibrate: onCalibrate,
              onMeasure: onMeasure,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(child: _SafetyNotice()),
        ],
      ),
    ],
  );
}

class _SpeedometerPanel extends StatelessWidget {
  const _SpeedometerPanel({required this.service});
  final PerformanceService service;

  static const _maxDisplaySpeed = 220.0;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: PerformanceColors.panel,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Text('● ', style: TextStyle(color: PerformanceColors.gold)),
            Text(
              tr.performanceSpeedometerTitle,
              style: const TextStyle(
                color: PerformanceColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.4,
          child: CustomPaint(
            painter: _SpeedometerPainter(
              speedKmh: service.speedKmh,
              maxSpeed: _maxDisplaySpeed,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.gpsAvailable == false
                          ? '--'
                          : service.speedKmh.round().toString(),
                      style: const TextStyle(
                        color: PerformanceColors.textPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        color: PerformanceColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (service.gpsAvailable != true) ...[
          const SizedBox(height: 2),
          Text(
            service.gpsAvailable == null
                ? tr.performanceGpsSearching
                : tr.performanceSpeedUnavailable,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PerformanceColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '${tr.performanceSessionMax}: ${service.maxSpeedKmh.round()} km/h',
          style: const TextStyle(
            color: PerformanceColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _SpeedometerPainter extends CustomPainter {
  _SpeedometerPainter({required this.speedKmh, required this.maxSpeed});
  final double speedKmh;
  final double maxSpeed;

  static const _startAngle = math.pi * 0.75;
  static const _sweepAngle = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - 8;
    final background = Paint()
      ..color = PerformanceColors.radarLines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, background);

    final progress = (speedKmh / maxSpeed).clamp(0.0, 1.0);
    final fill = Paint()
      ..color = PerformanceColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepAngle * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) =>
      oldDelegate.speedKmh != speedKmh;
}

class _GForcePanel extends StatelessWidget {
  const _GForcePanel({required this.service, required this.trail});
  final PerformanceService service;
  final List<Offset> trail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: PerformanceColors.panel,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Text('● ', style: TextStyle(color: PerformanceColors.gold)),
            Text(
              tr.performanceGForceTitle,
              style: const TextStyle(
                color: PerformanceColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: _GForceRadarPainter(
                  point: Offset(service.lateralG, -service.longitudinalG),
                  peak: service.peakResultantG,
                  trail: trail,
                ),
                size: Size.infinite,
              ),
              if (!service.calibrated)
                Text(
                  tr.performanceCalibrateNeeded,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: PerformanceColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${service.resultantG.toStringAsFixed(2)} g',
          style: const TextStyle(
            color: PerformanceColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

class _GForceRadarPainter extends CustomPainter {
  _GForceRadarPainter({
    required this.point,
    required this.peak,
    required this.trail,
  });

  final Offset point;
  final double peak;
  final List<Offset> trail;

  static const _scaleMaxG = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final linePaint = Paint()
      ..color = PerformanceColors.radarLines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final ring in [0.5, 1.0, 1.5]) {
      canvas.drawCircle(center, radius * (ring / _scaleMaxG), linePaint);
    }
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      linePaint,
    );

    Offset toCanvas(Offset g) => Offset(
      center.dx + (g.dx / _scaleMaxG).clamp(-1.0, 1.0) * radius,
      center.dy + (g.dy / _scaleMaxG).clamp(-1.0, 1.0) * radius,
    );

    if (trail.length > 1) {
      final trailPaint = Paint()
        ..color = PerformanceColors.gold.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final path = Path()..moveTo(toCanvas(trail.first).dx, toCanvas(trail.first).dy);
      for (final item in trail.skip(1)) {
        final p = toCanvas(item);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, trailPaint);
    }

    if (peak > 0) {
      final peakPaint = Paint()
        ..color = PerformanceColors.goldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      final peakRadius = (peak / _scaleMaxG).clamp(0.0, 1.0) * radius;
      _drawDashedCircle(canvas, center, peakRadius, peakPaint);
    }

    final dotPaint = Paint()..color = PerformanceColors.gold;
    canvas.drawCircle(toCanvas(point), 6, dotPaint);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 40;
    for (var i = 0; i < dashCount; i += 2) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      final endAngle = ((i + 1) / dashCount) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GForceRadarPainter oldDelegate) => true;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.service,
    this.columns = 3,
    this.byFuelInline,
  });

  final PerformanceService service;
  final int columns;
  final List<PerformanceRecord>? byFuelInline;

  @override
  Widget build(BuildContext context) {
    final lateralDirection = service.lateralG > 0.05
        ? '→'
        : service.lateralG < -0.05
        ? '←'
        : '';
    final cards = <Widget>[
      _StatCard(
        label: tr.performanceLateral,
        value: '${service.lateralG.abs().toStringAsFixed(2)}g $lateralDirection',
      ),
      _StatCard(
        label: tr.performanceAcceleration,
        value: '${service.longitudinalG.toStringAsFixed(2)}g',
      ),
      _StatCard(
        label: tr.performanceSessionPeak,
        value: '${service.peakResultantG.toStringAsFixed(2)}g',
      ),
      _StatCard(
        label: tr.performanceZeroToSixty,
        value: service.zeroToSixtySeconds == null
            ? '--'
            : '${service.zeroToSixtySeconds!.toStringAsFixed(2)}s',
      ),
      if (byFuelInline == null)
        _StatCard(
          label: tr.performanceSixtyToHundred,
          value: service.zeroToHundredSeconds == null
              ? '--'
              : '${service.zeroToHundredSeconds!.toStringAsFixed(2)}s',
        )
      else
        _StatCard(
          label: '0–100 ${fuelLabel(PerformanceFuelType.gasoline)}',
          value: _bestFor(byFuelInline!, PerformanceFuelType.gasoline),
        ),
      if (byFuelInline == null)
        _StatCard(
          label: tr.performanceGpsStatus,
          value: service.gpsAvailable == null
              ? tr.performanceGpsSearching
              : service.gpsAvailable == true
              ? tr.performanceGpsReady
              : tr.performanceGpsDenied,
        )
      else
        _StatCard(
          label: '0–100 ${fuelLabel(PerformanceFuelType.ethanol)}',
          value: _bestFor(byFuelInline!, PerformanceFuelType.ethanol),
        ),
    ];
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 76,
      ),
      children: cards,
    );
  }

  String _bestFor(List<PerformanceRecord> records, PerformanceFuelType fuel) {
    final matching = records.where((item) => item.fuel == fuel);
    if (matching.isEmpty) return '--';
    final best = matching
        .map((item) => item.zeroToHundredSeconds)
        .reduce(math.min);
    return '${best.toStringAsFixed(2)}s';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: PerformanceColors.panel,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PerformanceColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PerformanceColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _ByFuelCard extends StatelessWidget {
  const _ByFuelCard({required this.records});
  final List<PerformanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final byFuel = <PerformanceFuelType, double>{};
    for (final record in records) {
      final current = byFuel[record.fuel];
      if (current == null || record.zeroToHundredSeconds < current) {
        byFuel[record.fuel] = record.zeroToHundredSeconds;
      }
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PerformanceColors.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.performanceByFuelTitle,
            style: const TextStyle(
              color: PerformanceColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (byFuel.isEmpty)
            Text(
              tr.performanceByFuelEmpty,
              style: const TextStyle(
                color: PerformanceColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            for (final entry in byFuel.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fuelLabel(entry.key),
                        style: const TextStyle(
                          color: PerformanceColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(2)}s',
                      style: const TextStyle(
                        color: PerformanceColors.gold,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TestControls extends StatelessWidget {
  const _TestControls({
    required this.service,
    required this.onCalibrate,
    required this.onMeasure,
  });

  final PerformanceService service;
  final VoidCallback onCalibrate;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (service.testState) {
      ZeroToHundredState.armed => tr.performanceArmed,
      ZeroToHundredState.measuring => tr.performanceMeasuring,
      ZeroToHundredState.completed => tr.performanceCompleted,
      ZeroToHundredState.cancelled => tr.performanceCancelled,
      ZeroToHundredState.idle => null,
    };
    final calibrationText = switch (service.calibrationStep) {
      CalibrationStep.holdStill => tr.performanceCalibratingHoldStill,
      CalibrationStep.accelerate => tr.performanceCalibratingAccelerate,
      CalibrationStep.failed => tr.performanceCalibrationFailed,
      CalibrationStep.idle => null,
    };
    final busy = service.testState == ZeroToHundredState.measuring ||
        service.calibrationStep != CalibrationStep.idle;
    return Column(
      children: [
        if (calibrationText != null) ...[
          Text(
            calibrationText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PerformanceColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (statusText != null) ...[
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PerformanceColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: busy ? null : onCalibrate,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PerformanceColors.buttonOutline),
                    foregroundColor: PerformanceColors.buttonOutline,
                  ),
                  child: Text(tr.performanceCalibrateButton),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: busy ? null : onMeasure,
                  style: FilledButton.styleFrom(
                    backgroundColor: PerformanceColors.gold,
                    foregroundColor: PerformanceColors.onGold,
                  ),
                  child: Text(tr.performanceMeasureButton),
                ),
              ),
            ),
          ],
        ),
        if (service.testState == ZeroToHundredState.armed ||
            service.testState == ZeroToHundredState.measuring)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: service.cancelZeroToHundred,
              child: Text(
                tr.performanceCancelButton,
                style: const TextStyle(color: PerformanceColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: PerformanceColors.panel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: PerformanceColors.gold.withValues(alpha: .4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: PerformanceColors.gold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tr.performanceSafetyWarning,
            style: const TextStyle(
              color: PerformanceColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RecordsList extends StatelessWidget {
  const _RecordsList({required this.records});
  final List<PerformanceRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tr.performanceRecordsEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PerformanceColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in byFuel.entries)
          _RecordTile(
            title:
                '${tr.performanceRecordBest0to100} · ${fuelLabel(entry.key)}',
            value: '${entry.value.zeroToHundredSeconds.toStringAsFixed(2)}s',
            date: entry.value.date,
          ),
        _RecordTile(
          title: tr.performanceRecordBestLateral,
          value: '${bestLateral.peakLateralGForce.toStringAsFixed(2)} g',
          date: bestLateral.date,
        ),
        _RecordTile(
          title: tr.performanceRecordBestBraking,
          value: '${bestBraking.peakBrakingGForce.toStringAsFixed(2)} g',
          date: bestBraking.date,
        ),
        _RecordTile(
          title: tr.performanceRecordTopSpeed,
          value: '${bestSpeed.topSpeedKmh.round()} km/h',
          date: bestSpeed.date,
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.title,
    required this.value,
    required this.date,
  });

  final String title;
  final String value;
  final DateTime date;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: PerformanceColors.panel,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PerformanceColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatDate(date),
                style: const TextStyle(
                  color: PerformanceColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: PerformanceColors.gold,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
