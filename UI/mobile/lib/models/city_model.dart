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

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      created: json['created'] != null ? DateTime.parse(json['created']) : DateTime.now(),
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'created': created.toIso8601String(),
    'modified': modified?.toIso8601String(),
  };
}
