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

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      userId: json['userId'],
      balance: (json['balance'] as num).toDouble(),
      created: DateTime.parse(json['created']),
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'balance': balance,
    };
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

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      walletId: json['walletId'],
      amount: json['amount'].toDouble(),
      type: WalletTransactionType.fromValue(json['type']),
      created: DateTime.parse(json['created']),
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
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

