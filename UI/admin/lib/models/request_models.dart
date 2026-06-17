class UserCreateRequest {
  final String username;
  final String email;
  final String password;
  final String passwordConfirm;
  final String firstName;
  final String lastName;
  final String? address;
  final String? city;

  const UserCreateRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.passwordConfirm,
    required this.firstName,
    required this.lastName,
    this.address,
    this.city,
  });

  Map<String, Object?> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'passwordConfirm': passwordConfirm,
    'firstName': firstName,
    'lastName': lastName,
    'address': address ?? '',
    'city': city ?? '',
  };
}

class UserUpdateRequestDto {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? address;
  final String? city;
  final bool? isActive;

  const UserUpdateRequestDto({
    this.email,
    this.firstName,
    this.lastName,
    this.address,
    this.city,
    this.isActive,
  });

  Map<String, Object?> toJson() => {
    if (email != null) 'email': email,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (isActive != null) 'isActive': isActive,
  };
}

class ChangePasswordRequestDto {
  final String password;
  final String passwordConfirm;

  const ChangePasswordRequestDto({
    required this.password,
    required this.passwordConfirm,
  });

  Map<String, Object?> toJson() => {
    'password': password,
    'passwordConfirm': passwordConfirm,
  };
}

class CityUpsertRequest {
  final String? name;
  final double? latitude;
  final double? longitude;

  const CityUpsertRequest({this.name, this.latitude, this.longitude});

  Map<String, Object?> toJson() => {
    if (name != null) 'name': name,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

class ParkingZoneCreateRequest {
  final String name;
  final String description;
  final String address;
  final int cityId;
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final double? dailyRate;

  const ParkingZoneCreateRequest({
    required this.name,
    required this.description,
    required this.address,
    required this.cityId,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    this.dailyRate,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'address': address,
    'cityId': cityId,
    'latitude': latitude,
    'longitude': longitude,
    'pricePerHour': pricePerHour,
    'dailyRate': dailyRate ?? 0,
    'isActive': false,
  };
}

class ParkingZoneUpdateRequest {
  final String? name;
  final String? description;
  final String? address;
  final int? cityId;
  final double? latitude;
  final double? longitude;
  final double? pricePerHour;
  final double? dailyRate;
  final bool? isActive;

  const ParkingZoneUpdateRequest({
    this.name,
    this.description,
    this.address,
    this.cityId,
    this.latitude,
    this.longitude,
    this.pricePerHour,
    this.dailyRate,
    this.isActive,
  });

  Map<String, Object?> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (address != null) 'address': address,
    if (cityId != null) 'cityId': cityId,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (pricePerHour != null) 'pricePerHour': pricePerHour,
    if (dailyRate != null) 'dailyRate': dailyRate,
    if (isActive != null) 'isActive': isActive,
  };
}

class ParkingSpotCreateRequest {
  final int parkingZoneId;
  final int type;
  final int? rowNumber;
  final int? columnNumber;
  final bool isAvailable;

  const ParkingSpotCreateRequest({
    required this.parkingZoneId,
    required this.type,
    required this.rowNumber,
    required this.columnNumber,
    required this.isAvailable,
  });

  Map<String, Object?> toJson() => {
    'parkingZoneId': parkingZoneId,
    'type': type,
    'rowNumber': rowNumber,
    'columnNumber': columnNumber,
    'isAvailable': isAvailable,
  };
}

class ParkingSpotUpdateRequest {
  final String? spotCode;
  final int? type;
  final int? rowNumber;
  final int? columnNumber;
  final bool? isAvailable;

  const ParkingSpotUpdateRequest({
    this.spotCode,
    this.type,
    this.rowNumber,
    this.columnNumber,
    this.isAvailable,
  });

  Map<String, Object?> toJson() => {
    if (spotCode != null) 'spotCode': spotCode,
    if (type != null) 'type': type,
    if (rowNumber != null) 'rowNumber': rowNumber,
    if (columnNumber != null) 'columnNumber': columnNumber,
    if (isAvailable != null) 'isAvailable': isAvailable,
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