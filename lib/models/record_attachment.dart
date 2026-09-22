class RecordAttachment {
  const RecordAttachment({
    required this.path,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  final String path;
  final String name;
  final String type;
  final DateTime createdAt;

  bool get isPdf => type == 'pdf';

  RecordAttachment copyWith({String? path}) => RecordAttachment(
    path: path ?? this.path,
    name: name,
    type: type,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecordAttachment.fromJson(Map<String, dynamic> json) =>
      RecordAttachment(
        path: json['path'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
