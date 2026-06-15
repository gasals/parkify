class City {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime created;
  final DateTime? modified;

  City({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.created,
    this.modified,
  });

  factory City.fromJson(Map<String, Object?> json) {
    return City(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      created: json['created'] != null
          ? DateTime.parse(json['created'] as String)
          : DateTime.now(),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'created': created.toIso8601String(),
    'modified': modified?.toIso8601String(),
  };
}
