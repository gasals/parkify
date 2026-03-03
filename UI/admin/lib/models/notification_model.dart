class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final int type;
  final int channel;
  final int? reservationId;
  final int? parkingZoneId;
  final bool isRead;
  final DateTime created;
  final DateTime? readDate;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.channel,
    this.reservationId,
    this.parkingZoneId,
    required this.isRead,
    required this.created,
    this.readDate,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as int,
      channel: json['channel'] as int? ?? 1,
      reservationId: json['reservationId'] as int?,
      parkingZoneId: json['parkingZoneId'] as int?,
      isRead: json['isRead'] as bool,
      created: DateTime.parse(json['created'] as String),
      readDate: json['readDate'] != null
          ? DateTime.parse(json['readDate'] as String)
          : null,
    );
  }

  AppNotification copyWith({bool? isRead, DateTime? readDate}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      channel: channel,
      reservationId: reservationId,
      parkingZoneId: parkingZoneId,
      isRead: isRead ?? this.isRead,
      created: created,
      readDate: readDate ?? this.readDate,
    );
  }
}
