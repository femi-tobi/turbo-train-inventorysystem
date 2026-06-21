class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String role; // 'admin' or 'staff'
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password_hash': passwordHash,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        username: map['username'] as String,
        passwordHash: map['password_hash'] as String,
        role: map['role'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
