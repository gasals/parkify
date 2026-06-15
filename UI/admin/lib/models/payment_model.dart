class Payment {
  final int id;
  final String paymentCode;
  final int reservationId;
  final int userId;
  final double amount;
  final String currency;
  final int status;
  final String stripePaymentIntentId;
  final String clientSecret;
  final String transactionId;
  final DateTime created;
  final DateTime? completed;
  final DateTime? refunded;
  final String refundReason;

  Payment({
    required this.id,
    required this.paymentCode,
    required this.reservationId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.stripePaymentIntentId,
    required this.clientSecret,
    required this.transactionId,
    required this.created,
    this.completed,
    this.refunded,
    this.refundReason = '',
  });

  factory Payment.fromJson(Map<String, Object?> json) {
    return Payment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      paymentCode: json['paymentCode'] as String? ?? '',
      reservationId: (json['reservationId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'bam',
      status: (json['status'] as num?)?.toInt() ?? 1,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
      created: json['created'] != null
        ? DateTime.parse(json['created'] as String)
          : DateTime.now(),
      completed: json['completed'] != null
        ? DateTime.parse(json['completed'] as String)
          : null,
      refunded: json['refunded'] != null
        ? DateTime.parse(json['refunded'] as String)
          : null,
      refundReason: json['refundReason'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'paymentCode': paymentCode,
      'reservationId': reservationId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'stripePaymentIntentId': stripePaymentIntentId,
      'clientSecret': clientSecret,
      'transactionId': transactionId,
      'created': created.toIso8601String(),
      'completed': completed?.toIso8601String(),
      'refunded': refunded?.toIso8601String(),
      'refundReason': refundReason,
    };
  }
}
