class Vehicle {
  const Vehicle({
    required this.id,
    required this.nickname,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuel,
    required this.transmission,
    required this.mileage,
    required this.createdAt,
    required this.documents,
    required this.photos,
    this.vehicleType = 'car',
  });

  final String id;
  final String nickname;
  final String brand;
  final String model;
  final int year;
  final String fuel;
  final String transmission;
  final int mileage;
  final DateTime createdAt;
  final List<DocumentYear> documents;
  final List<VehiclePhoto> photos;
  final String vehicleType;

  bool get isMotorcycle => vehicleType == 'motorcycle';
  String get typeLabel => isMotorcycle ? 'Moto' : 'Carro';

  Vehicle copyWith({
    String? nickname,
    String? brand,
    String? model,
    int? year,
    String? fuel,
    String? transmission,
    int? mileage,
    List<DocumentYear>? documents,
    List<VehiclePhoto>? photos,
    String? vehicleType,
  }) => Vehicle(
    id: id,
    nickname: nickname ?? this.nickname,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    year: year ?? this.year,
    fuel: fuel ?? this.fuel,
    transmission: transmission ?? this.transmission,
    mileage: mileage ?? this.mileage,
    createdAt: createdAt,
    documents: documents ?? this.documents,
    photos: photos ?? this.photos,
    vehicleType: vehicleType ?? this.vehicleType,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'brand': brand,
    'model': model,
    'year': year,
    'fuel': fuel,
    'transmission': transmission,
    'mileage': mileage,
    'createdAt': createdAt.toIso8601String(),
    'documents': documents.map((item) => item.toJson()).toList(),
    'photos': photos.map((item) => item.toJson()).toList(),
    'vehicleType': vehicleType,
  };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String,
    nickname: json['nickname'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    year: json['year'] as int,
    fuel: json['fuel'] as String,
    transmission: json['transmission'] as String,
    mileage: json['mileage'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    documents: (json['documents'] as List<dynamic>)
        .map((item) => DocumentYear.fromJson(item as Map<String, dynamic>))
        .toList(),
    photos: (json['photos'] as List<dynamic>)
        .map((item) => VehiclePhoto.fromJson(item as Map<String, dynamic>))
        .toList(),
    vehicleType: json['vehicleType'] as String? ?? 'car',
  );
}

class DocumentYear {
  DocumentYear(this.year, {this.ipvaPaid = false, this.licensingPaid = false});

  int year;
  bool ipvaPaid;
  bool licensingPaid;

  Map<String, dynamic> toJson() => {
    'year': year,
    'ipvaPaid': ipvaPaid,
    'licensingPaid': licensingPaid,
  };

  factory DocumentYear.fromJson(Map<String, dynamic> json) => DocumentYear(
    json['year'] as int,
    ipvaPaid: json['ipvaPaid'] as bool,
    licensingPaid: json['licensingPaid'] as bool,
  );
}

class VehiclePhoto {
  const VehiclePhoto(this.path, this.type, this.date);

  final String path;
  final String type;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'path': path,
    'type': type,
    'date': date.toIso8601String(),
  };

  factory VehiclePhoto.fromJson(Map<String, dynamic> json) => VehiclePhoto(
    json['path'] as String,
    json['type'] as String,
    DateTime.parse(json['date'] as String),
  );
}
