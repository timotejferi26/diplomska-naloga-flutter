// lib/data/datasources/user_fake_datasource.dart
//
// PURPOSE:
//   A datasource pre-seeded with N generated users.
//   This is what benchmark runs actually use — it starts with a full
//   dataset so the "load" benchmark measures rendering cost, not
//   data generation cost.
//
// DIFFERENCE FROM UserLocalDataSource:
//   UserLocalDataSource starts empty — users are added one at a time.
//   UserFakeDataSource starts pre-populated — used for load/paginate/search
//   benchmarks where you need data already present.
//
// USED BY:
//   - BenchmarkConfig (swapped in when a run starts)
//   - All library DI setups when benchmarkMode = true

import 'package:diplomska_naloga/core/services/logger_service.dart';
import 'package:diplomska_naloga/data/datasources/fake_user_generator.dart';
import 'package:diplomska_naloga/data/datasources/user_datasource_interface.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';

class UserFakeDataSource implements IUserDataSource {
  final List<User> _storage;
  final ILogger _logger;

  UserFakeDataSource({required int count, int seed = 42, ILogger? logger})
    : _storage = FakeUserGenerator.generate(count, seed: seed),
      _logger = logger ?? const SilentLogger() {
    _logger.info(
      'UserFakeDataSource: seeded with ${_storage.length} users (seed=$seed)',
    );
  }

  // ── Read ──────────────────────────────────────────────────────

  @override
  Future<List<User>> getAllUsers({int page = 1, int pageSize = 20}) async {
    final skip = (page - 1) * pageSize;
    final result = _storage.skip(skip).take(pageSize).toList();
    _logger.info(
      'UserFakeDataSource.getAllUsers: '
      'page=$page, returned=${result.length}/${_storage.length}',
    );
    return result;
  }

  @override
  Future<List<User>> filterUsers(String query) async {
    if (query.trim().isEmpty) return List.unmodifiable(_storage);
    final lower = query.toLowerCase();
    final result = _storage.where((u) {
      return u.name.toLowerCase().contains(lower) ||
          u.email.toLowerCase().contains(lower) ||
          u.tags.any((t) => t.toLowerCase().contains(lower));
    }).toList();
    _logger.info(
      'UserFakeDataSource.filterUsers: query="$query", found=${result.length}',
    );
    return result;
  }

  @override
  Future<int> getTotalCount() async => _storage.length;

  // ── Write ─────────────────────────────────────────────────────

  @override
  Future<User> addUser(User user) async {
    _storage.add(user);
    _logger.info('UserFakeDataSource.addUser: id=${user.id}');
    return user;
  }

  @override
  Future<User> updateUser(User user) async {
    final index = _storage.indexWhere((u) => u.id == user.id);
    if (index == -1) throw StateError('User ${user.id} not found');
    _storage[index] = user;
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    final before = _storage.length;
    _storage.removeWhere((u) => u.id == id);
    if (_storage.length == before) throw StateError('User $id not found');
  }
}
