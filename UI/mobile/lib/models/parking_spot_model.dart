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

  factory ParkingSpot.fromJson(Map<String, Object?> json) {
    return ParkingSpot(
      id: json['id'] as int? ?? 0,
      spotCode: json['spotCode'] as String? ?? '',
      parkingZoneId: json['parkingZoneId'] as int? ?? 0,
      type: json['type'] as int? ?? 0,
      rowNumber: json['rowNumber'] as int?,
      columnNumber: json['columnNumber'] as int?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      created: json['created'] != null
          ? DateTime.parse(json['created'] as String)
          : DateTime.now(),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
    );
  }

  String getTypeText() {
    return ParkingSpotType.fromValue(type).label;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'spotCode': spotCode,
      'parkingZoneId': parkingZoneId,
      'type': type,
      'rowNumber': rowNumber,
      'columnNumber': columnNumber,
      'isAvailable': isAvailable,
      'created': created.toIso8601String(),
      'modified': modified?.toIso8601String(),
    };
  }
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
