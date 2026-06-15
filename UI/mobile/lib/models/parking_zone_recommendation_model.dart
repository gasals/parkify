import 'parking_zone_model.dart';

class ParkingZoneRecommendation {
  final ParkingZone zone;
  final double score;
  final List<String> reasons;

  ParkingZoneRecommendation({
    required this.zone,
    required this.score,
    required this.reasons,
  });

  factory ParkingZoneRecommendation.fromJson(Map<String, Object?> json) {
    final zoneJson = Map<String, Object?>.from(
      (json['zone'] ?? json['Zone'] ?? <String, Object?>{}) as Map,
    );

    final rawReasons = (json['reasons'] ?? json['Reasons']) as List?;

    return ParkingZoneRecommendation(
      zone: ParkingZone.fromJson(zoneJson),
      score: ((json['score'] ?? json['Score']) as num?)?.toDouble() ?? 0.0,
      reasons:
          rawReasons
              ?.map((reason) => reason?.toString() ?? '')
              .where((reason) => reason.isNotEmpty)
              .toList() ??
          <String>[],
    );
  }
}
