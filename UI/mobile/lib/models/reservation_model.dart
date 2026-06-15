class Reservation {
  final int id;
  final String reservationCode;
  final int userId;
  final int parkingZoneId;
  final int parkingSpotId;
  final DateTime reservationStart;
  final DateTime reservationEnd;
  final int durationInHours;
  final int status;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final double calculatedPrice;
  final double? discountAmount;
  final double finalPrice;
  final bool requiresDisabledSpot;
  final String notes;
  final DateTime created;
  final DateTime? modified;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  Reservation({
    required this.id,
    required this.reservationCode,
    required this.userId,
    required this.parkingZoneId,
    required this.parkingSpotId,
    required this.reservationStart,
    required this.reservationEnd,
    required this.durationInHours,
    required this.status,
    required this.isCheckedIn,
    required this.isCheckedOut,
    required this.calculatedPrice,
    this.discountAmount,
    required this.finalPrice,
    required this.requiresDisabledSpot,
    required this.notes,
    required this.created,
    this.modified,
    this.checkInTime,
    this.checkOutTime,
  });

  factory Reservation.fromJson(Map<String, Object?> json) {
    return Reservation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reservationCode: json['reservationCode'] as String? ?? '',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      parkingZoneId: (json['parkingZoneId'] as num?)?.toInt() ?? 0,
      parkingSpotId: (json['parkingSpotId'] as num?)?.toInt() ?? 0,
      reservationStart: DateTime.parse(
        json['reservationStart'] as String? ?? DateTime.now().toString(),
      ),
      reservationEnd: DateTime.parse(
        json['reservationEnd'] as String? ?? DateTime.now().toString(),
      ),
      durationInHours: (json['durationInHours'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 1,
      isCheckedIn: json['isCheckedIn'] as bool? ?? false,
      isCheckedOut: json['isCheckedOut'] as bool? ?? false,
      calculatedPrice: (json['calculatedPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: json['discountAmount'] != null
          ? (json['discountAmount'] as num).toDouble()
          : null,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      requiresDisabledSpot: json['requiresDisabledSpot'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      created: DateTime.parse(
        json['created'] as String? ?? DateTime.now().toString(),
      ),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
    );
  }

  String getStatusText() {
    switch (status) {
      case 1:
        return 'Na čekanju';
      case 2:
        return 'Potvrđena';
      case 3:
        return 'Aktivna';
      case 4:
        return 'Završena';
      case 5:
        return 'Otkazana';
      case 6:
        return 'Izostanak';
      default:
        return 'Nepoznato';
    }
  }
}

enum ReservationStatus {
  pending(1, 'Na čekanju'),
  confirmed(2, 'Potvrđena'),
  active(3, 'Aktivna'),
  completed(4, 'Završena'),
  cancelled(5, 'Otkazana'),
  noShow(6, 'Izostanak');

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
