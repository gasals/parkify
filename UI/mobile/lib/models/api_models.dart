class AuthSession {
  final String token;
  final int id;
  final bool isAdmin;
  final bool isActive;

  const AuthSession({
    required this.token,
    required this.id,
    required this.isAdmin,
    required this.isActive,
  });

  factory AuthSession.fromJson(Map<String, Object?> json) {
    return AuthSession(
      token: json['token'] as String? ?? json['Token'] as String? ?? '',
      id: (json['id'] as num?)?.toInt() ?? 0,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class PagedResponse<T> {
  final List<T> results;
  final int count;

  const PagedResponse({required this.results, required this.count});

  factory PagedResponse.fromJson(
    Map<String, Object?> json,
    T Function(Map<String, Object?> item) fromJson,
  ) {
    final rawResults = json['results'] as List? ?? const [];

    return PagedResponse<T>(
      results: rawResults
          .whereType<Map>()
          .map((item) => fromJson(item.cast<String, Object?>()))
          .toList(),
      count: (json['count'] as num?)?.toInt() ?? rawResults.length,
    );
  }
}

class PaymentIntentResult {
  final int id;
  final String paymentCode;
  final String clientSecret;
  final String stripePaymentIntentId;
  final double amount;
  final int status;

  const PaymentIntentResult({
    required this.id,
    required this.paymentCode,
    required this.clientSecret,
    required this.stripePaymentIntentId,
    required this.amount,
    required this.status,
  });

  factory PaymentIntentResult.fromJson(Map<String, Object?> json) {
    return PaymentIntentResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      paymentCode: json['paymentCode'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      stripePaymentIntentId: json['stripePaymentIntentId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
    );
  }
}