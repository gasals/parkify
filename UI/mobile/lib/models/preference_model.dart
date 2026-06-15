class Preference {
  final int id;
  final int userId;
  final bool prefersNearby;
  final int? preferredCityId;
  final int? favoriteParkingZoneId;
  final bool notifyAboutOffers;
  final DateTime created;
  final DateTime? modified;

  Preference({
    required this.id,
    required this.userId,
    this.prefersNearby = true,
    this.preferredCityId,
    this.favoriteParkingZoneId,
    this.notifyAboutOffers = true,
    required this.created,
    this.modified,
  });

  factory Preference.fromJson(Map<String, Object?> json) {
    return Preference(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      prefersNearby: json['prefersNearby'] as bool? ?? true,
      preferredCityId: (json['preferredCityId'] as num?)?.toInt(),
      favoriteParkingZoneId: (json['favoriteParkingZoneId'] as num?)?.toInt(),
      notifyAboutOffers: json['notifyAboutOffers'] as bool? ?? true,
      created: DateTime.parse(
        json['created'] as String? ?? DateTime.now().toString(),
      ),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
    );
  }
}
