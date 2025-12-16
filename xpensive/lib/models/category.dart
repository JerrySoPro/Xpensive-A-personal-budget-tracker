class Category {
  final String id;
  final String userId;
  final String name;
  final String type; // 'income' or 'expense'
  final String color;
  final String icon;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      type: map['type'],
      color: map['color'],
      icon: map['icon'],
    );
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? color,
    String? icon,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
