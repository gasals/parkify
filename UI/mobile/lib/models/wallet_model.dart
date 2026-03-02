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