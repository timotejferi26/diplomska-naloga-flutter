import 'package:diplomska_naloga/domain/entities/role.dart';

/// The User entity
class User {
  final String id;
  final String name;
  final String email;
  final Role role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    Role? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! User) return false;
    return id == other.id &&
        name == other.name &&
        email == other.email &&
        role == other.role &&
        isActive == other.isActive &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        _listEquals(tags, other.tags);
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    role,
    isActive,
    createdAt,
    updatedAt,
    Object.hashAll(tags),
  );

  @override
  String toString() =>
      'User(\n'
      'id: $id,\n'
      'name: $name,\n'
      'email: $email,\n'
      'role: ${role.label},\n'
      'isActive: $isActive,\n'
      'createdAt: $createdAt,\n'
      'updatedAt: $updatedAt,\n'
      'tags: $tags,\n'
      ')';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
