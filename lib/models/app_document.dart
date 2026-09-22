class AppDocument {
  const AppDocument({
    required this.id,
    required this.type,
    required this.path,
    required this.originalName,
    required this.importedAt,
    this.vehicleId,
  });

  final String id;
  final String type;
  final String path;
  final String originalName;
  final DateTime importedAt;
  final String? vehicleId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'path': path,
    'originalName': originalName,
    'importedAt': importedAt.toIso8601String(),
    if (vehicleId != null) 'vehicleId': vehicleId,
  };

  factory AppDocument.fromJson(Map<String, dynamic> json) => AppDocument(
    id: json['id'] as String,
    type: json['type'] as String,
    path: json['path'] as String,
    originalName: json['originalName'] as String,
    importedAt: DateTime.parse(json['importedAt'] as String),
    vehicleId: json['vehicleId'] as String?,
  );
}
