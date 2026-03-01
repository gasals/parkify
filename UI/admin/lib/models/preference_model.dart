class Preference {
  final int id;
  final int userId;
  final bool prefersCovered;
  final bool prefersNearby;
  final int? preferredCityId;
  final int? favoriteParkingZoneId;
  final bool notifyAboutOffers;
  final DateTime created;
  final DateTime? modified;

  Preference({
    required this.id,
    required this.userId,
    this.prefersCovered = false,
    this.prefersNearby = true,
    this.preferredCityId,
    this.favoriteParkingZoneId,
    this.notifyAboutOffers = true,
    required this.created,
    this.modified,
  });

  factory Preference.fromJson(Map<String, dynamic> json) {
    return Preference(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      prefersCovered: json['prefersCovered'] ?? false,
      prefersNearby: json['prefersNearby'] ?? true,
      preferredCityId: json['preferredCityId'],
      favoriteParkingZoneId: json['favoriteParkingZoneId'],
      notifyAboutOffers: json['notifyAboutOffers'] ?? true,
      created: DateTime.parse(
        json['created'] ?? DateTime.now().toString(),
      ),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'])
          : null,
    );
  }
}
