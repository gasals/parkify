import 'vehicle_model.dart';

class UserRegistrationRequest {
  final String username;
  final String email;
  final String password;
  final String passwordConfirm;
  final String firstName;
  final String lastName;
  final String? address;
  final String? city;
  final String? phoneNumber;

  const UserRegistrationRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.passwordConfirm,
    required this.firstName,
    required this.lastName,
    this.address,
    this.city,
    this.phoneNumber,
  });

  Map<String, Object?> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'passwordConfirm': passwordConfirm,
    'firstName': firstName,
    'lastName': lastName,
    'address': address,
    'city': city,
    'phoneNumber': phoneNumber,
  };
}

class UserUpdateRequestDto {
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  const UserUpdateRequestDto({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  Map<String, Object?> toJson() => {
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
  };
}

class ChangePasswordRequestDto {
  final String currentPassword;
  final String password;
  final String passwordConfirm;

  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.password,
    required this.passwordConfirm,
  });

  Map<String, Object?> toJson() => {
    'currentPassword': currentPassword,
    'password': password,
    'passwordConfirm': passwordConfirm,
  };
}

class ReservationCreateRequest {
  final int userId;
  final int parkingZoneId;
  final int parkingSpotId;
  final DateTime reservationStart;
  final DateTime reservationEnd;
  final String vehicleLicensePlate;
  final bool requiresDisabledSpot;
  final String? notes;

  const ReservationCreateRequest({
    required this.userId,
    required this.parkingZoneId,
    required this.parkingSpotId,
    required this.reservationStart,
    required this.reservationEnd,
    required this.vehicleLicensePlate,
    required this.requiresDisabledSpot,
    this.notes,
  });

  Map<String, Object?> toJson() => {
    'userId': userId,
    'parkingZoneId': parkingZoneId,
    'parkingSpotId': parkingSpotId,
    'reservationStart': reservationStart.toIso8601String(),
    'reservationEnd': reservationEnd.toIso8601String(),
    'vehicleLicensePlate': vehicleLicensePlate,
    'requiresDisabledSpot': requiresDisabledSpot,
    'notes': notes,
  };
}

class PaymentCreateRequest {
  final int? reservationId;
  final int? walletId;
  final int userId;
  final double amount;
  final String currency;

  const PaymentCreateRequest({
    this.reservationId,
    this.walletId,
    required this.userId,
    required this.amount,
    this.currency = 'bam',
  });

  Map<String, Object?> toJson() => {
    'reservationId': reservationId,
    'walletId': walletId,
    'userId': userId,
    'amount': amount,
    'currency': currency,
  };
}

class PreferenceUpdateRequest {
  final bool? prefersNearby;
  final int? preferredCityId;
  final int? favoriteParkingZoneId;
  final bool? notifyAboutOffers;

  const PreferenceUpdateRequest({
    this.prefersNearby,
    this.preferredCityId,
    this.favoriteParkingZoneId,
    this.notifyAboutOffers,
  });

  Map<String, Object?> toJson() => {
    if (prefersNearby != null) 'prefersNearby': prefersNearby,
    if (preferredCityId != null) 'preferredCityId': preferredCityId,
    if (favoriteParkingZoneId != null)
      'favoriteParkingZoneId': favoriteParkingZoneId,
    if (notifyAboutOffers != null) 'notifyAboutOffers': notifyAboutOffers,
  };
}

class ReviewUpsertRequest {
  final int? parkingZoneId;
  final int? userId;
  final int rating;
  final String? reviewText;

  const ReviewUpsertRequest({
    this.parkingZoneId,
    this.userId,
    required this.rating,
    this.reviewText,
  });

  Map<String, Object?> toJson() => {
    if (parkingZoneId != null) 'parkingZoneId': parkingZoneId,
    if (userId != null) 'userId': userId,
    'rating': rating,
    'reviewText': reviewText,
  };
}

class VehicleUpdateRequest {
  final int userId;
  final String licensePlate;
  final String model;
  final VehicleCategory category;

  const VehicleUpdateRequest({
    required this.userId,
    required this.licensePlate,
    required this.model,
    required this.category,
  });

  Map<String, Object?> toJson() => {
    'userId': userId,
    'licensePlate': licensePlate,
    'model': model,
    'category': category.value,
  };
}

class NotificationSendRequest {
  final int? userId;
  final String title;
  final String message;
  final int type;
  final int channel;

  const NotificationSendRequest({
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.channel,
  });

  Map<String, Object?> toJson() => {
    if (userId != null) 'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'channel': channel,
  };
}