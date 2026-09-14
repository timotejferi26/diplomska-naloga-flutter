// lib/data/datasources/user_datasource_interface.dart
//
// PURPOSE:
//   Contract between UserRepositoryImpl and its storage backends.
//   There are three implementations:
//     - UserLocalDataSource  (in-memory List, default for benchmarks)
//     - UserFakeDataSource   (pre-seeded with N generated users)
//     - UserRemoteDataSource (simulates network delay + failures)
//
// NOTE ON LOCATION:
//   This interface lives in data/datasources/ (NOT data/entities/ — that
//   was a typo in the original codebase). Datasource interfaces belong
//   beside their implementations.
//
// USED BY:
//   - UserRepositoryImpl (injected via constructor)
//   - All three datasource implementations

import 'package:diplomska_naloga/domain/entities/user.dart';

abstract interface class IUserDataSource {
  /// Returns a paginated slice of users.
  Future<List<User>> getAllUsers({int page = 1, int pageSize = 20});

  /// Returns all users matching [query] in name or email (case-insensitive).
  Future<List<User>> filterUsers(String query);

  /// Persists [user] and returns it.
  Future<User> addUser(User user);

  /// Replaces the stored record for [user.id] and returns the updated user.
  /// Throws [StateError] if the user is not found.
  Future<User> updateUser(User user);

  /// Removes the user with [id].
  /// Throws [StateError] if the user is not found.
  Future<void> deleteUser(String id);

  /// Returns the total number of users currently in storage.
  /// Used by controllers to know when all pages have been loaded.
  Future<int> getTotalCount();
}
