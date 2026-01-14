class User {
  final String id;
  final String username;
  final String passwordHash;
  final String email;
  final String displayName;
  final String? profilePhoto;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.email,
    required this.displayName,
    this.profilePhoto,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'email': email,
      'displayName': displayName,
      'profilePhoto': profilePhoto,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['passwordHash'] ?? map['password_hash'] ?? '',
      email: map['email'],
      displayName: map['displayName'] ?? map['display_name'],
      profilePhoto: map['profilePhoto'] ?? map['profile_photo'],
      createdAt: DateTime.parse(map['createdAt'] ?? map['created_at']),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'])
          : (map['last_login'] != null
                ? DateTime.parse(map['last_login'])
                : null),
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? email,
    String? displayName,
    String? profilePhoto,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
