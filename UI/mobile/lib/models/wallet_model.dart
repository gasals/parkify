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
  final String description;
  final DateTime created;
  final DateTime? modified;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.description,
    required this.created,
    this.modified,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      walletId: json['walletId'],
      amount: json['amount'].toDouble(),
      description: json['description'] ?? '',
      created: DateTime.parse(json['created']),
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
    );
  }
}