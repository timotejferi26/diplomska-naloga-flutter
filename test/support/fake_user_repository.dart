import 'dart:async';

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/domain/entities/role.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/exceptions/not_found_exception.dart';
import 'package:diplomska_naloga/domain/exceptions/validation_exception.dart';
import 'package:diplomska_naloga/domain/repositories/user_repository.dart';
import 'package:diplomska_naloga/domain/usecases/add_user_usecase.dart';
import 'package:diplomska_naloga/domain/usecases/delete_user_usecase.dart';
import 'package:diplomska_naloga/domain/usecases/get_users_usecase.dart';
import 'package:diplomska_naloga/domain/usecases/search_user_usecase.dart';
import 'package:diplomska_naloga/domain/usecases/update_user_usecase.dart';

final DateTime testTime = DateTime.utc(2026, 1, 1);

User testUser({
  required String id,
  required String name,
  required String email,
  List<String> tags = const [],
}) {
  return User(
    id: id,
    name: name,
    email: email,
    role: Role.user,
    isActive: true,
    createdAt: testTime,
    updatedAt: testTime,
    tags: tags,
  );
}

List<User> standardUsers() => [
  testUser(id: 'user-1', name: 'Ana Novak', email: 'ana@example.com'),
  testUser(id: 'user-2', name: 'Boris Kralj', email: 'boris@example.com'),
];

/// Deterministic replacement for the data layer used by every library test.
class FakeUserRepository implements IUserRepository {
  FakeUserRepository({List<User>? users, this.getUsersGate})
    : _users = List<User>.of(users ?? standardUsers());

  final List<User> _users;
  // A test-controlled gate makes asynchronous initialization observable without
  // sleeps or a second loadUsers() call. It is not a production dependency.
  final Future<void>? getUsersGate;
  final Completer<void> _firstReadStarted = Completer<void>();
  Future<void> get firstReadStarted => _firstReadStarted.future;

  final getAllUsersCalls = <({int page, int pageSize})>[];
  final filterQueries = <String>[];
  final createdUsers = <({String name, String email, List<String> tags})>[];
  final updatedUsers = <User>[];
  final deletedUserIds = <String>[];

  List<User> get users => List<User>.unmodifiable(_users);
  int _nextId = 3;

  @override
  Future<List<User>> getAllUsers({int page = 1, int pageSize = 20}) async {
    getAllUsersCalls.add((page: page, pageSize: pageSize));
    if (!_firstReadStarted.isCompleted) _firstReadStarted.complete();
    if (getUsersGate != null) await getUsersGate;
    final start = (page - 1) * pageSize;
    if (start >= _users.length) return [];
    final end = (start + pageSize).clamp(0, _users.length);
    return List<User>.of(_users.sublist(start, end));
  }

  @override
  Future<List<User>> filterUsers(String query) async {
    filterQueries.add(query);
    final normalized = query.trim().toLowerCase();
    return _users.where((user) {
      return user.name.toLowerCase().contains(normalized) ||
          user.email.toLowerCase().contains(normalized) ||
          user.tags.any((tag) => tag.toLowerCase().contains(normalized));
    }).toList();
  }

  @override
  Future<User> createUser({
    required String name,
    required String email,
    required List<String> tags,
  }) async {
    createdUsers.add((name: name, email: email, tags: List<String>.of(tags)));
    if (name.trim().length < 2) {
      throw const ValidationException('Name must be at least 2 characters.');
    }
    if (!email.contains('@')) {
      throw const ValidationException('Email address is not valid.');
    }

    final user = testUser(
      id: 'user-${_nextId++}',
      name: name.trim(),
      email: email.trim(),
      tags: List<String>.of(tags),
    );
    _users.insert(0, user);
    return user;
  }

  @override
  Future<User> updateUser(User user) async {
    updatedUsers.add(user);
    final index = _users.indexWhere((candidate) => candidate.id == user.id);
    if (index == -1) throw NotFoundException(user.id);
    final updated = user.copyWith(
      updatedAt: testTime.add(const Duration(days: 1)),
    );
    _users[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteUser(String id) async {
    deletedUserIds.add(id);
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) throw NotFoundException(id);
    _users.removeAt(index);
  }
}

// Keep the real use cases and substitute only their repository dependency.
UserUseCases buildTestUseCases({required IUserRepository repository}) {
  return UserUseCases(
    getUsers: GetUsersUseCase(repository),
    addUser: AddUserUseCase(repository),
    updateUser: UpdateUserUseCase(repository),
    deleteUser: DeleteUserUseCase(repository),
    searchUsers: SearchUsersUseCase(repository),
  );
}
