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
  final int availableSpots;
  final double pricePerHour;
  final double dailyRate;
  final bool isActive;
  bool isFavorite;
  List<ParkingSpot>? spots;
  double averageRating = 0.0;
  int reviewCount = 0;

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
    required this.availableSpots,
    required this.pricePerHour,
    required this.dailyRate,
    required this.isActive,
    this.isFavorite = false,
    this.spots,
  });

  factory ParkingZone.fromJson(Map<String, Object?> json) {
    return ParkingZone(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      cityId: (json['cityId'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      totalSpots: (json['totalSpots'] as num?)?.toInt() ?? 0,
      disabledSpots: (json['disabledSpots'] as num?)?.toInt() ?? 0,
      availableSpots: (json['availableSpots'] as num?)?.toInt() ?? 0,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      isFavorite: json['isFavorite'] as bool? ?? false,
      spots: (json['spots'] as List?)
          ?.whereType<Map>()
          .map((spot) => ParkingSpot.fromJson(spot.cast<String, Object?>()))
          .toList(),
    )
      ..averageRating = (json['averageRating'] as num?)?.toDouble() ?? 0.0
      ..reviewCount = (json['reviewCount'] as num?)?.toInt() ?? 0;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'address': address,
    'cityId': cityId,
    'latitude': latitude,
    'longitude': longitude,
    'totalSpots': totalSpots,
    'disabledSpots': disabledSpots,
    'availableSpots': availableSpots,
    'pricePerHour': pricePerHour,
    'dailyRate': dailyRate,
    'isActive': isActive,
    'isFavorite': isFavorite,
    'averageRating': averageRating,
    'reviewCount': reviewCount,
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

  ParkingSpot({
    required this.id,
    required this.parkingZoneId,
    required this.spotCode,
    required this.rowNumber,
    required this.columnNumber,
    required this.type,
    required this.isAvailable,
  });

  factory ParkingSpot.fromJson(Map<String, Object?> json) {
    return ParkingSpot(
      id: (json['id'] as num?)?.toInt() ?? 0,
      parkingZoneId: (json['parkingZoneId'] as num?)?.toInt() ?? 0,
      spotCode: json['spotCode'] as String? ?? '',
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
      columnNumber: (json['columnNumber'] as num?)?.toInt() ?? 0,
      type: (json['type'] as num?)?.toInt() ?? 1,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'parkingZoneId': parkingZoneId,
    'spotCode': spotCode,
    'rowNumber': rowNumber,
    'columnNumber': columnNumber,
    'type': type,
    'isAvailable': isAvailable,
  };
}

enum ParkingSpotType {
  regular(1, 'Regular'),
  disabled(2, 'Invalidsko'),
  covered(3, 'Pokriveno');

  final int value;
  final String label;

  const ParkingSpotType(this.value, this.label);

  static ParkingSpotType fromValue(int value) {
    return ParkingSpotType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ParkingSpotType.regular,
    );
  }
}
