class Wallet {
  final int id;
  final int userId;
  final double balance;
  final DateTime created;
  final DateTime? modified;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.created,
    this.modified,
  });

  factory Wallet.fromJson(Map<String, Object?> json) {
    return Wallet(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num).toDouble(),
      created: DateTime.parse(json['created'] as String),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return {'userId': userId, 'balance': balance};
  }
}

class WalletTransaction {
  final int id;
  final int walletId;
  final double amount;
  final WalletTransactionType type;
  final DateTime created;
  final DateTime? modified;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.created,
    this.modified,
  });

  factory WalletTransaction.fromJson(Map<String, Object?> json) {
    return WalletTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      walletId: (json['walletId'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: WalletTransactionType.fromValue(
        (json['type'] as num?)?.toInt() ?? WalletTransactionType.deposit.value,
      ),
      created: DateTime.parse(json['created'] as String),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
    );
  }
}

enum WalletTransactionType {
  reservation(1, 'Rezervacija'),
  deposit(2, 'Uplata'),
  cancellation(3, 'Otkazivanje');

  final int value;
  final String label;

  const WalletTransactionType(this.value, this.label);

  static WalletTransactionType fromValue(int value) {
    return WalletTransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WalletTransactionType.deposit,
    );
  }

  static WalletTransactionType? fromValueNullable(int? value) {
    if (value == null) return null;
    return fromValue(value);
  }
}
