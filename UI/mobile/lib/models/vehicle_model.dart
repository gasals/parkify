enum VehicleCategory {
  am,
  a1,
  a2,
  a,
  b,
  be,
  c1,
  c1e,
  c,
  ce,
  d1,
  d1e,
  d,
  de,
  f,
  g,
  h;

  static VehicleCategory fromValue(int? value) {
    if (value == null || value < 1 || value > VehicleCategory.values.length) {
      return VehicleCategory.b;
    }

    return VehicleCategory.values[value - 1];
}

class Vehicle {
  final int id;
  final int userId;
  final String licensePlate;
  final VehicleCategory category;
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

  String get categoryLabel {
    switch (category) {
      case VehicleCategory.am:
        return 'AM';
      case VehicleCategory.a1:
        return 'A1';
      case VehicleCategory.a2:
        return 'A2';
      case VehicleCategory.a:
        return 'A';
      case VehicleCategory.b:
        return 'B';
      case VehicleCategory.be:
        return 'B E';
      case VehicleCategory.c1:
        return 'C1';
      case VehicleCategory.c1e:
        return 'C1 E';
      case VehicleCategory.c:
        return 'C';
      case VehicleCategory.ce:
        return 'C E';
      case VehicleCategory.d1:
        return 'D1';
      case VehicleCategory.d1e:
        return 'D1 E';
      case VehicleCategory.d:
        return 'D';
      case VehicleCategory.de:
        return 'D E';
      case VehicleCategory.f:
        return 'F';
      case VehicleCategory.g:
        return 'G';
      case VehicleCategory.h:
        return 'H';
    }
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      userId: json['userId'],
      licensePlate: json['licensePlate'],
      category: VehicleCategory.fromValue(json['category'] as int?),
      model: json['model'],
      created: DateTime.parse(json['created']),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'licensePlate': licensePlate,
      'category': category.index + 1,
      'model': model,
    };
  }
}
