class Transaction {
  final String id;
  final String? userId;
  final String accountId;
  final String categoryId;
  final double amount;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String? description;
  final bool isRecurring;
  final String? recurringId;
  final String? receiptPhoto;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    this.userId,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.description,
    this.isRecurring = false,
    this.recurringId,
    this.receiptPhoto,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'description': description,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
      'receiptPhoto': receiptPhoto,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['userId'],
      accountId: map['accountId'] ?? map['account_id'],
      categoryId: map['categoryId'] ?? map['category_id'],
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : (map['amount'] as num).toDouble(),
      type: map['type'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      isRecurring: map['isRecurring'] == true || map['is_recurring'] == 1,
      recurringId: map['recurringId'] ?? map['recurring_id'],
      receiptPhoto: map['receiptPhoto'] ?? map['receipt_photo'],
      createdAt: DateTime.parse(map['createdAt'] ?? map['created_at']),
      updatedAt: DateTime.parse(map['updatedAt'] ?? map['updated_at']),
    );
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    double? amount,
    String? type,
    DateTime? date,
    String? description,
    bool? isRecurring,
    String? recurringId,
    String? receiptPhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      receiptPhoto: receiptPhoto ?? this.receiptPhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
