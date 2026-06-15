enum PaymentStatus {
  pending(1, 'Pending'),
  processing(2, 'Processing'),
  completed(3, 'Completed'),
  failed(4, 'Failed'),
  refunded(5, 'Refunded');

  final int value;
  final String label;

  const PaymentStatus(this.value, this.label);

  static PaymentStatus fromValue(int value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class Payment {
  int id;
  String paymentCode;
  int? reservationId;
  int? walletId;
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
    this.reservationId,
    this.walletId,
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
      reservationId: (json['reservationId'] as num?)?.toInt(),
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
}
