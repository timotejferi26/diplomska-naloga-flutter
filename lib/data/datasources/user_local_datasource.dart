// lib/data/datasources/user_local_datasource.dart
//
// PURPOSE:
//   In-memory storage backed by a List<User>.
//   This is the default datasource used in benchmark runs — it has zero
//   I/O overhead so timing results reflect state management costs, not
//   storage costs.
//
// PAGINATION:
//   Implemented via skip/take on the in-memory list.
//   page is 1-based: page 1 returns items 0..(pageSize-1).
//
// FILTERING:
//   Case-insensitive substring match on name and email.
//
// THREAD SAFETY:
//   Not thread-safe — Dart is single-threaded in the UI isolate so
//   this is fine for all benchmark scenarios.
//
// USED BY:
//   - UserRepositoryImpl (injected as IUserDataSource)
//   - Riverpod, Provider, watch_it DI setup

import 'package:diplomska_naloga/core/services/logger_service.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'user_datasource_interface.dart';

class UserLocalDataSource implements IUserDataSource {
  final List<User> _storage = [];
  final ILogger _logger;

  UserLocalDataSource({ILogger? logger})
    : _logger = logger ?? const SilentLogger();

  // ── Read ──────────────────────────────────────────────────────

  @override
  Future<List<User>> getAllUsers({int page = 1, int pageSize = 20}) async {
    final skip = (page - 1) * pageSize;
    final result = _storage.skip(skip).take(pageSize).toList();
    _logger.info(
      'UserLocalDataSource.getAllUsers: '
      'page=$page, returned=${result.length}/${_storage.length}',
    );
    return result;
  }

  @override
  Future<List<User>> filterUsers(String query) async {
    if (query.trim().isEmpty) {
      return List.unmodifiable(_storage);
    }
    final lower = query.toLowerCase();
    final result = _storage.where((u) {
      return u.name.toLowerCase().contains(lower) ||
          u.email.toLowerCase().contains(lower) ||
          u.tags.any((t) => t.toLowerCase().contains(lower));
    }).toList();
    _logger.info(
      'UserLocalDataSource.filterUsers: '
      'query="$query", found=${result.length}',
    );
    return result;
  }

  @override
  Future<int> getTotalCount() async => _storage.length;

  // ── Write ─────────────────────────────────────────────────────

  @override
  Future<User> addUser(User user) async {
    _storage.add(user);
    _logger.info('UserLocalDataSource.addUser: id=${user.id}');
    return user;
  }

  @override
  Future<User> updateUser(User user) async {
    final index = _storage.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      _logger.error('UserLocalDataSource.updateUser: not found id=${user.id}');
      throw StateError('User ${user.id} not found');
    }
    _storage[index] = user;
    _logger.info('UserLocalDataSource.updateUser: id=${user.id}');
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    final removed = _storage.length;
    _storage.removeWhere((u) => u.id == id);
    if (_storage.length == removed) {
      _logger.warning('UserLocalDataSource.deleteUser: not found id=$id');
      throw StateError('User $id not found');
    }
    _logger.info('UserLocalDataSource.deleteUser: id=$id');
  }

  // ── Utility (used by FakeDataSource seeding) ──────────────────

  /// Clears all data. Used between benchmark runs.
  void clear() {
    _storage.clear();
    _logger.info('UserLocalDataSource.clear: storage emptied');
  }

  /// Bulk-inserts a list of users without logging each one.
  /// Much faster than calling addUser() N times for large datasets.
  void seed(List<User> users) {
    _storage.addAll(users);
    _logger.info('UserLocalDataSource.seed: added ${users.length} users');
  }
}
