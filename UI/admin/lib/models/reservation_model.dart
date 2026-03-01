class Reservation {
  final int id;
  final String reservationCode;
  final int userId;
  final int parkingZoneId;
  final int parkingSpotId;
  final int? spotCode;
  final String? parkingZoneName;
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
    this.spotCode,
    this.parkingZoneName,
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
    final start = DateTime.parse(json['reservationStart'] as String? ?? '');
    final end = DateTime.parse(json['reservationEnd'] as String? ?? '');
    final duration = (json['durationInHours'] as int?) ?? 
        (end.difference(start).inMinutes / 60).ceil();

    return Reservation(
      id: json['id'] as int? ?? 0,
      reservationCode: json['reservationCode'] as String? ?? '',
      userId: json['userId'] as int? ?? 0,
      parkingZoneId: json['parkingZoneId'] as int? ?? 0,
      parkingSpotId: json['parkingSpotId'] as int? ?? 0,
      spotCode: json['spotCode'] as int?,
      parkingZoneName: json['parkingZoneName'] as String?,
      reservationStart: start,
      reservationEnd: end,
      durationInHours: duration,
      status: json['status'] as int? ?? 1,
      isCheckedIn: json['isCheckedIn'] as bool? ?? false,
      isCheckedOut: json['isCheckedOut'] as bool? ?? false,
      calculatedPrice: (json['calculatedPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      requiresDisabledSpot: json['requiresDisabledSpot'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      qrCodeData: json['qrCodeData'] as String? ?? '',
      created: json['created'] != null
          ? DateTime.parse(json['created'] as String)
          : DateTime.now(),
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
        return 'Pending';
      case 2:
        return 'Confirmed';
      case 3:
        return 'Active';
      case 4:
        return 'Completed';
      case 5:
        return 'Cancelled';
      case 6:
        return 'NoShow';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservationCode': reservationCode,
      'userId': userId,
      'parkingZoneId': parkingZoneId,
      'parkingSpotId': parkingSpotId,
      'reservationStart': reservationStart.toIso8601String(),
      'reservationEnd': reservationEnd.toIso8601String(),
      'durationInHours': durationInHours,
      'status': status,
      'isCheckedIn': isCheckedIn,
      'isCheckedOut': isCheckedOut,
      'calculatedPrice': calculatedPrice,
      'discountAmount': discountAmount,
      'finalPrice': finalPrice,
      'requiresDisabledSpot': requiresDisabledSpot,
      'notes': notes,
      'qrCodeData': qrCodeData,
      'created': created.toIso8601String(),
      'modified': modified?.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
    };
  }
}