class Vehicle {
  final int id;
  final int userId;
  final String licensePlate;
  final String category;
  final String model;
  final DateTime? created;
  final DateTime? modified;

  Vehicle({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.category,
    required this.model,
    this.created,
    this.modified,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      userId: json['userId'],
      licensePlate: json['licensePlate'],
      category: json['category'],
      model: json['model'],
      created: DateTime.parse(json['created']),
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'licensePlate': licensePlate,
      'category': category,
      'model': model,
    };
  }
}