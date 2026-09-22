enum EstablishmentType {
  posto('Posto de combustível'),
  oficina('Oficina'),
  concessionaria('Concessionária'),
  lavaJato('Lava-jato'),
  seguradora('Seguradora'),
  outro('Outro');

  const EstablishmentType(this.label);
  final String label;
}

class Establishment {
  const Establishment({
    required this.id,
    required this.name,
    required this.type,
    this.brand,
    this.address,
    this.neighborhood,
    this.favorite = false,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final EstablishmentType type;
  final String? brand;
  final String? address;
  final String? neighborhood;
  final bool favorite;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Establishment copyWith({
    String? name,
    EstablishmentType? type,
    String? brand,
    String? address,
    String? neighborhood,
    bool? favorite,
    bool? active,
    DateTime? updatedAt,
  }) => Establishment(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    brand: brand ?? this.brand,
    address: address ?? this.address,
    neighborhood: neighborhood ?? this.neighborhood,
    favorite: favorite ?? this.favorite,
    active: active ?? this.active,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    if (brand != null) 'brand': brand,
    if (address != null) 'address': address,
    if (neighborhood != null) 'neighborhood': neighborhood,
    'favorite': favorite,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Establishment.fromJson(Map<String, dynamic> json) => Establishment(
    id: json['id'] as String,
    name: json['name'] as String,
    type: EstablishmentType.values.byName(json['type'] as String? ?? 'outro'),
    brand: json['brand'] as String?,
    address: json['address'] as String?,
    neighborhood: json['neighborhood'] as String?,
    favorite: json['favorite'] as bool? ?? false,
    active: json['active'] as bool? ?? true,
    createdAt: json['createdAt'] == null
        ? DateTime.now()
        : DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] == null
        ? DateTime.now()
        : DateTime.parse(json['updatedAt'] as String),
  );
}
