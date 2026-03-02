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

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      paymentCode: json['paymentCode'] ?? '',
      reservationId: json['reservationId'] ?? 0,
      userId: json['userId'] ?? 0,
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'bam',
      status: json['status'] ?? 1,
      stripePaymentIntentId: json['stripePaymentIntentId'] ?? '',
      clientSecret: json['clientSecret'] ?? '',
      transactionId: json['transactionId'] ?? '',
      created: json['created'] != null ? DateTime.parse(json['created']) : DateTime.now(),
      completed:
          json['completed'] != null ? DateTime.parse(json['completed']) : null,
      refunded: json['refunded'] != null ? DateTime.parse(json['refunded']) : null,
      refundReason: json['refundReason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
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
