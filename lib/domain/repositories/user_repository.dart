import 'package:diplomska_naloga/domain/entities/user.dart';

/// The repository interface for user-related data operations.
abstract class IUserRepository {
  Future<List<User>> getAllUsers({int page = 1, int pageSize = 20});

  /// Returns users whose name, email, or tags contain [query] (case-insensitive).
  Future<List<User>> filterUsers(String query);

  /// Creates a new user. Repository assigns id, role, timestamps.
  Future<User> createUser({
    required String name,
    required String email,
    required List<String> tags,
  });

  /// Replaces the stored user. Repository updates updatedAt.
  Future<User> updateUser(User user);

  /// Permanently removes the user with [id].
  Future<void> deleteUser(String id);
}
