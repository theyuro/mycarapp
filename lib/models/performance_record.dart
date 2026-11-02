import 'dart:convert';

/// Combustível usado no teste 0–100 (mesmas opções do formulário de
/// abastecimento; ver fuelGasoline, fuelEthanol etc. em lib/l10n/app_pt.arb).
enum PerformanceFuelType { gasoline, ethanol, diesel, naturalGas, electric, flex, hybrid }

/// Um teste de 0–100 km/h concluído, usado nos recordes da tela Desempenho.
/// Os tempos (0–60 e 0–100) são aproximados: dependem da frequência do GPS,
/// que atualiza cerca de 1 vez por segundo.
class PerformanceRecord {
  PerformanceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.fuel,
    required this.zeroToSixtySeconds,
    required this.zeroToHundredSeconds,
    this.peakGForce = 0,
    this.peakLateralGForce = 0,
    this.peakBrakingGForce = 0,
    this.topSpeedKmh = 0,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final PerformanceFuelType fuel;
  final double zeroToSixtySeconds;
  final double zeroToHundredSeconds;
  final double peakGForce;
  final double peakLateralGForce;
  final double peakBrakingGForce;
  final double topSpeedKmh;

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'date': date.toIso8601String(),
    'fuel': fuel.name,
    'zeroToSixtySeconds': zeroToSixtySeconds,
    'zeroToHundredSeconds': zeroToHundredSeconds,
    'peakGForce': peakGForce,
    'peakLateralGForce': peakLateralGForce,
    'peakBrakingGForce': peakBrakingGForce,
    'topSpeedKmh': topSpeedKmh,
  };

  factory PerformanceRecord.fromJson(Map<String, dynamic> json) =>
      PerformanceRecord(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        date: DateTime.parse(json['date'] as String),
        fuel: PerformanceFuelType.values.firstWhere(
          (item) => item.name == json['fuel'],
          orElse: () => PerformanceFuelType.gasoline,
        ),
        zeroToSixtySeconds: (json['zeroToSixtySeconds'] as num).toDouble(),
        zeroToHundredSeconds: (json['zeroToHundredSeconds'] as num).toDouble(),
        peakGForce: (json['peakGForce'] as num?)?.toDouble() ?? 0,
        peakLateralGForce: (json['peakLateralGForce'] as num?)?.toDouble() ?? 0,
        peakBrakingGForce: (json['peakBrakingGForce'] as num?)?.toDouble() ?? 0,
        topSpeedKmh: (json['topSpeedKmh'] as num?)?.toDouble() ?? 0,
      );

  static List<PerformanceRecord> listFromJson(String source) =>
      (jsonDecode(source) as List)
          .cast<Map<String, dynamic>>()
          .map(PerformanceRecord.fromJson)
          .toList();

  static String listToJson(List<PerformanceRecord> records) =>
      jsonEncode(records.map((item) => item.toJson()).toList());
}
