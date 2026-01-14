class Category {
  final String id;
  final String userId;
  final String name;
  final String type; // 'income' or 'expense'
  final String color;
  final String icon;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      userId: map['userId'] ?? map['user_id'],
      name: map['name'],
      type: map['type'],
      color: map['color'],
      icon: map['icon'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
    );
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
