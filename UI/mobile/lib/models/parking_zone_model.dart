class ParkingZone {
  final int id;
  final String name;
  final String description;
  final String address;
  final int cityId;
  final double latitude;
  final double longitude;
  final int totalSpots;
  final int disabledSpots;
  final int coveredSpots;
  final int availableSpots;
  final double pricePerHour;
  final double dailyRate;
  final bool isActive;
  bool isFavorite;
  final List<ParkingSpot>? spots;

  ParkingZone({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.cityId,
    required this.latitude,
    required this.longitude,
    required this.totalSpots,
    required this.disabledSpots,
    required this.coveredSpots,
    required this.availableSpots,
    required this.pricePerHour,
    required this.dailyRate,
    required this.isActive,
    this.isFavorite = false,
    this.spots,
  });

  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    return ParkingZone(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      cityId: json['cityId'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      totalSpots: json['totalSpots'] ?? 0,
      disabledSpots: json['disabledSpots'] ?? 0,
      coveredSpots: json['coveredSpots'] ?? 0,
      availableSpots: json['availableSpots'] ?? 0,
      pricePerHour: (json['pricePerHour'] ?? 0.0).toDouble(),
      dailyRate: (json['dailyRate'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
      isFavorite: json['isFavorite'] ?? false,
      spots: (json['spots'] as List?)
          ?.map((spot) => ParkingSpot.fromJson(spot))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'address': address,
    'cityId': cityId,
    'latitude': latitude,
    'longitude': longitude,
    'totalSpots': totalSpots,
    'disabledSpots': disabledSpots,
    'coveredSpots': coveredSpots,
    'availableSpots': availableSpots,
    'pricePerHour': pricePerHour,
    'dailyRate': dailyRate,
    'isActive': isActive,
    'isFavorite': isFavorite,
    'spots': spots?.map((spot) => spot.toJson()).toList(),
  };
}

class ParkingSpot {
  final int id;
  final int parkingZoneId;
  final String spotCode;
  final int rowNumber;
  final int columnNumber;
  final int type;
  final bool isAvailable;
  final bool isCovered;

  ParkingSpot({
    required this.id,
    required this.parkingZoneId,
    required this.spotCode,
    required this.rowNumber,
    required this.columnNumber,
    required this.type,
    required this.isAvailable,
    required this.isCovered,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] ?? 0,
      parkingZoneId: json['parkingZoneId'] ?? 0,
      spotCode: json['spotCode'] ?? '',
      rowNumber: json['rowNumber'] ?? 0,
      columnNumber: json['columnNumber'] ?? 0,
      type: json['type'] ?? 1,
      isAvailable: json['isAvailable'] ?? true,
      isCovered: json['isCovered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parkingZoneId': parkingZoneId,
    'spotCode': spotCode,
    'rowNumber': rowNumber,
    'columnNumber': columnNumber,
    'type': type,
    'isAvailable': isAvailable,
    'isCovered': isCovered,
  };
}