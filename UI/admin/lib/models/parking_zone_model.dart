import 'package:admin/models/parking_spot_model.dart';

class ParkingZone {
  final int id;
  final String name;
  final String address;
  final String? description;
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
  final DateTime created;
  final DateTime? modified;
  final List<ParkingSpot>? spots;

  ParkingZone({
    required this.id,
    required this.name,
    required this.address,
    this.description,
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
    required this.created,
    this.modified,
    this.spots,
  });

  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    return ParkingZone(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String?,
      cityId: json['cityId'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      totalSpots: json['totalSpots'] as int? ?? 0,
      disabledSpots: json['disabledSpots'] as int? ?? 0,
      coveredSpots: json['coveredSpots'] as int? ?? 0,
      availableSpots: json['availableSpots'] as int? ?? 0,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      created: json['created'] != null
          ? DateTime.parse(json['created'] as String)
          : DateTime.now(),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
      spots: (json['spots'] as List<dynamic>?)
          ?.map((spot) => ParkingSpot.fromJson(spot as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
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
      'created': created.toIso8601String(),
      'modified': modified?.toIso8601String(),
    };
  }
}

enum ReservationStatus {
  pending(1, 'Pending'),
  confirmed(2, 'Confirmed'),
  active(3, 'Active'),
  completed(4, 'Completed'),
  cancelled(5, 'Cancelled'),
  noShow(6, 'NoShow');

  final int value;
  final String label;

  const ReservationStatus(this.value, this.label);

  static ReservationStatus fromValue(int value) {
    return ReservationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReservationStatus.pending,
    );
  }

  static ReservationStatus? fromValueNullable(int? value) {
    if (value == null) return null;
    return fromValue(value);
  }
}
