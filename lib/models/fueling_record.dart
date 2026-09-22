import 'record_attachment.dart';

class FuelingRecord {
  const FuelingRecord({
    required this.id,
    required this.vehicleId,
    required this.liters,
    required this.totalPrice,
    required this.date,
    this.mileage,
    this.fuelType,
    this.station,
    this.establishmentId,
    this.fullTank = false,
    this.tankCapacityLiters,
    this.gaugeMarkedFull = false,
    this.notes,
    this.attachments = const [],
  });

  final String id;
  final String vehicleId;
  final double liters;
  final double totalPrice;
  final DateTime date;
  final int? mileage;
  final String? fuelType;
  final String? station;

  /// Id do [Establishment] selecionado no lançamento. Registros antigos ou
  /// não migrados continuam usando apenas [station] como texto livre.
  final String? establishmentId;
  final bool fullTank;
  final double? tankCapacityLiters;
  final bool gaugeMarkedFull;
  final String? notes;
  final List<RecordAttachment> attachments;

  double get pricePerLiter => liters == 0 ? 0 : totalPrice / liters;

  FuelingRecord copyWith({
    double? liters,
    double? totalPrice,
    DateTime? date,
    int? mileage,
    String? fuelType,
    String? station,
    String? establishmentId,
    bool? fullTank,
    double? tankCapacityLiters,
    bool? gaugeMarkedFull,
    String? notes,
    List<RecordAttachment>? attachments,
  }) => FuelingRecord(
    id: id,
    vehicleId: vehicleId,
    liters: liters ?? this.liters,
    totalPrice: totalPrice ?? this.totalPrice,
    date: date ?? this.date,
    mileage: mileage ?? this.mileage,
    fuelType: fuelType ?? this.fuelType,
    station: station ?? this.station,
    establishmentId: establishmentId ?? this.establishmentId,
    fullTank: fullTank ?? this.fullTank,
    tankCapacityLiters: tankCapacityLiters ?? this.tankCapacityLiters,
    gaugeMarkedFull: gaugeMarkedFull ?? this.gaugeMarkedFull,
    notes: notes ?? this.notes,
    attachments: attachments ?? this.attachments,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'liters': liters,
    'totalPrice': totalPrice,
    'date': date.toIso8601String(),
    if (mileage != null) 'mileage': mileage,
    if (fuelType != null) 'fuelType': fuelType,
    if (station != null) 'station': station,
    if (establishmentId != null) 'establishmentId': establishmentId,
    'fullTank': fullTank,
    if (tankCapacityLiters != null) 'tankCapacityLiters': tankCapacityLiters,
    'gaugeMarkedFull': gaugeMarkedFull,
    if (notes != null) 'notes': notes,
    'attachments': attachments.map((item) => item.toJson()).toList(),
  };

  factory FuelingRecord.fromJson(Map<String, dynamic> json) => FuelingRecord(
    id: json['id'] as String,
    vehicleId: json['vehicleId'] as String,
    liters: (json['liters'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    mileage: (json['mileage'] as num?)?.toInt(),
    fuelType: json['fuelType'] as String?,
    station: json['station'] as String?,
    establishmentId: json['establishmentId'] as String?,
    fullTank: json['fullTank'] as bool? ?? false,
    tankCapacityLiters: (json['tankCapacityLiters'] as num?)?.toDouble(),
    gaugeMarkedFull: json['gaugeMarkedFull'] as bool? ?? false,
    notes: json['notes'] as String?,
    attachments: (json['attachments'] as List<dynamic>? ?? const [])
        .map((item) => RecordAttachment.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
