class Payment {
  int id;
  String paymentCode;
  int reservationId;
  int userId;
  double amount;
  String currency;
  int status;
  String stripePaymentIntentId;
  String clientSecret;
  String transactionId;
  DateTime created;
  DateTime? completed;
  DateTime? refunded;
  String refundReason;

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
      completed: json['completed'] != null ? DateTime.parse(json['completed']) : null,
      refunded: json['refunded'] != null ? DateTime.parse(json['refunded']) : null,
      refundReason: json['refundReason'] ?? '',
    );
  }
}