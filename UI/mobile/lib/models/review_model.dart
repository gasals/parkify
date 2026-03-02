import 'package:mobile/models/parking_zone_model.dart';
import 'package:mobile/models/user_model.dart';

class Review {
  final int id;
  final int parkingZoneId;
  final int userId;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;
  final User? author;
  final ParkingZone? parkingZone;

  Review({
    required this.id,
    required this.parkingZoneId,
    required this.userId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    this.author,
    this.parkingZone,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      parkingZoneId: json['parkingZoneId'] ?? 0,
      userId: json['userId'] ?? 0,
      rating: json['rating'] ?? 0,
      reviewText: json['reviewText'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      author: json['author'] != null ? User.fromJson(json['author']) : null,
      parkingZone: json['parkingZone'] != null
          ? ParkingZone.fromJson(json['parkingZone'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parkingZoneId': parkingZoneId,
      'userId': userId,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': createdAt.toIso8601String(),
      'author': author?.toJson(),
      'parkingZone': parkingZone?.toJson(),
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0 && difference.inHours == 0) {
      return 'Prije ${difference.inMinutes} minuta';
    } else if (difference.inDays == 0) {
      return 'Prije ${difference.inHours} sati';
    } else if (difference.inDays < 7) {
      return 'Prije ${difference.inDays} dana';
    } else {
      return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    }
  }
}
