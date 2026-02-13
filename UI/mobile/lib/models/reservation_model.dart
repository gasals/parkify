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
  final String qrCodeData;
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
    required this.qrCodeData,
    required this.created,
    this.modified,
    this.checkInTime,
    this.checkOutTime,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? 0,
      reservationCode: json['reservationCode'] ?? '',
      userId: json['userId'] ?? 0,
      parkingZoneId: json['parkingZoneId'] ?? 0,
      parkingSpotId: json['parkingSpotId'] ?? 0,
      reservationStart: DateTime.parse(json['reservationStart'] ?? DateTime.now().toString()),
      reservationEnd: DateTime.parse(json['reservationEnd'] ?? DateTime.now().toString()),
      durationInHours: json['durationInHours'] ?? 0,
      status: json['status'] ?? 1,
      isCheckedIn: json['isCheckedIn'] ?? false,
      isCheckedOut: json['isCheckedOut'] ?? false,
      calculatedPrice: (json['calculatedPrice'] ?? 0).toDouble(),
      discountAmount: json['discountAmount'] != null ? (json['discountAmount']).toDouble() : null,
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      requiresDisabledSpot: json['requiresDisabledSpot'] ?? false,
      notes: json['notes'] ?? '',
      qrCodeData: json['qrCodeData'] ?? '',
      created: DateTime.parse(json['created'] ?? DateTime.now().toString()),
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
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
