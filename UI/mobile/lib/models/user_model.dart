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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      address: json['address'],
      city: json['city'],
      phoneNumber: json['phoneNumber'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
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
