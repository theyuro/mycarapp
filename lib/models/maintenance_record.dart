import 'record_attachment.dart';

const _unset = Object();

class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.service,
    required this.category,
    required this.date,
    required this.mileage,
    this.workshop,
    this.establishmentId,
    this.laborCost = 0,
    this.partsCost = 0,
    this.notes,
    this.nextMileage,
    this.nextDate,
    this.isCompleted = true,
    this.attachments = const [],
  });

  final String id;
  final String vehicleId;
  final String service;
  final String category;
  final DateTime date;
  final int mileage;
  final String? workshop;

  /// Id do [Establishment] selecionado no lançamento. Registros antigos ou
  /// não migrados continuam usando apenas [workshop] como texto livre.
  final String? establishmentId;
  final double laborCost;
  final double partsCost;
  final String? notes;
  final int? nextMileage;
  final DateTime? nextDate;
  final bool isCompleted;
  final List<RecordAttachment> attachments;

  double get totalCost => laborCost + partsCost;

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'service': service,
    'category': category,
    'date': date.toIso8601String(),
    'mileage': mileage,
    'laborCost': laborCost,
    'partsCost': partsCost,
    if (workshop != null) 'workshop': workshop,
    if (establishmentId != null) 'establishmentId': establishmentId,
    if (notes != null) 'notes': notes,
    if (nextMileage != null) 'nextMileage': nextMileage,
    if (nextDate != null) 'nextDate': nextDate!.toIso8601String(),
    'isCompleted': isCompleted,
    'attachments': attachments.map((item) => item.toJson()).toList(),
  };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        service: json['service'] as String,
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        mileage: (json['mileage'] as num).toInt(),
        workshop: json['workshop'] as String?,
        establishmentId: json['establishmentId'] as String?,
        laborCost: (json['laborCost'] as num? ?? 0).toDouble(),
        partsCost: (json['partsCost'] as num? ?? 0).toDouble(),
        notes: json['notes'] as String?,
        nextMileage: (json['nextMileage'] as num?)?.toInt(),
        nextDate: json['nextDate'] == null
            ? null
            : DateTime.parse(json['nextDate'] as String),
        isCompleted: json['isCompleted'] as bool? ?? true,
        attachments: (json['attachments'] as List<dynamic>? ?? const [])
            .map(
              (item) => RecordAttachment.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  MaintenanceRecord copyWith({
    List<RecordAttachment>? attachments,
    Object? establishmentId = _unset,
  }) => MaintenanceRecord(
    id: id,
    vehicleId: vehicleId,
    service: service,
    category: category,
    date: date,
    mileage: mileage,
    workshop: workshop,
    establishmentId: establishmentId == _unset
        ? this.establishmentId
        : establishmentId as String?,
    laborCost: laborCost,
    partsCost: partsCost,
    notes: notes,
    nextMileage: nextMileage,
    nextDate: nextDate,
    isCompleted: isCompleted,
    attachments: attachments ?? this.attachments,
  );
}
