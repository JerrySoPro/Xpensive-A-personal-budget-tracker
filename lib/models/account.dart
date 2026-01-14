class Account {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['userId'] ?? map['user_id'],
      name: map['name'],
      type: map['type'],
      balance: map['balance'] is int
          ? (map['balance'] as int).toDouble()
          : (map['balance'] as num).toDouble(),
      currency: map['currency'],
      createdAt: DateTime.parse(map['createdAt'] ?? map['created_at']),
      updatedAt: DateTime.parse(map['updatedAt'] ?? map['updated_at']),
    );
  }

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? balance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
