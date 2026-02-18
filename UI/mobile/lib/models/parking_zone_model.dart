class ParkingZone {
  final int id;
  final String name;
  final String description;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final int totalSpots;
  final int disabledSpots;
  final int coveredSpots;
  final int availableSpots;
  final double pricePerHour;
  final double dailyRate;
  final bool isActive;
  final DateTime created;
  final DateTime? modified;
  final List<ParkingSpot>? spots;

  ParkingZone({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.totalSpots,
    required this.disabledSpots,
    required this.coveredSpots,
    required this.availableSpots,
    required this.pricePerHour,
    required this.dailyRate,
    this.isActive = true,
    required this.created,
    this.modified,
    this.spots,
  });

  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    return ParkingZone(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      totalSpots: json['totalSpots'] ?? 0,
      disabledSpots: json['disabledSpots'] ?? 0,
      coveredSpots: json['coveredSpots'] ?? 0,
      availableSpots: json['availableSpots'] ?? 0,
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      dailyRate: (json['dailyRate'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      created: DateTime.parse(json['created'] ?? DateTime.now().toString()),
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
      spots: json['spots'] != null ? (json['spots'] as List).map((e) => ParkingSpot.fromJson(e)).toList() : null,
    );
  }
}

class ParkingSpot {
  final int id;
  final String spotCode;
  final int parkingZoneId;
  final int type;
  final int? rowNumber;
  final int? columnNumber;
  final bool isAvailable;
  final DateTime created;
  final DateTime? modified;

  ParkingSpot({
    required this.id,
    required this.spotCode,
    required this.parkingZoneId,
    required this.type,
    this.rowNumber,
    this.columnNumber,
    required this.isAvailable,
    required this.created,
    this.modified,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] ?? 0,
      spotCode: json['spotCode'] ?? '',
      parkingZoneId: json['parkingZoneId'] ?? 0,
      type: json['type'] ?? 1,
      rowNumber: json['rowNumber'],
      columnNumber: json['columnNumber'],
      isAvailable: json['isAvailable'] ?? true,
      created: DateTime.parse(json['created'] ?? DateTime.now().toString()),
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
    );
  }
}
