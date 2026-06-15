enum VehicleCategory {
  am(1, 'AM'),
  a1(2, 'A1'),
  a2(3, 'A2'),
  a(4, 'A'),
  b(5, 'B'),
  be(6, 'B E'),
  c1(7, 'C1'),
  c1e(8, 'C1 E'),
  c(9, 'C'),
  ce(10, 'C E'),
  d1(11, 'D1'),
  d1e(12, 'D1 E'),
  d(13, 'D'),
  de(14, 'D E'),
  f(15, 'F'),
  g(16, 'G'),
  h(17, 'H');

  final int value;
  final String label;

  const VehicleCategory(this.value, this.label);

  static VehicleCategory fromValue(int? value) {
    return VehicleCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => VehicleCategory.b,
    );
  }
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

  String get categoryLabel => category.label;

  factory Vehicle.fromJson(Map<String, Object?> json) {
    return Vehicle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      licensePlate: json['licensePlate'] as String? ?? '',
      category: VehicleCategory.fromValue((json['category'] as num?)?.toInt()),
      model: json['model'] as String? ?? '',
      created: json['created'] != null
          ? DateTime.parse(json['created'] as String)
          : null,
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'licensePlate': licensePlate,
      'category': category.value,
      'model': model,
    };
  }
}
