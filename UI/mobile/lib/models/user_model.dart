class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? address;
  final String? city;
  final String? phoneNumber;
  final bool isActive;
  final bool isAdmin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.address,
    this.city,
    this.phoneNumber,
    this.isActive = true,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, Object?> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'address': address,
      'city': city,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
    };
  }
}
