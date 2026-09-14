// lib/data/repositories/user_repository_impl.dart
//
// PURPOSE:
//   Concrete implementation of IUserRepository.
//   Validates input, enriches writes (id, timestamps), and throws
//   typed exceptions on failure so controllers can catch specifically.
//
// EXCEPTION FLOW:
//   ValidationException  — thrown by validator, re-thrown as-is
//   NotFoundException    — thrown when id doesn't exist in storage
//   StorageException     — wraps any unexpected datasource error

import 'package:diplomska_naloga/core/services/clock_service.dart';
import 'package:diplomska_naloga/core/services/id_generator.dart';
import 'package:diplomska_naloga/core/services/logger_service.dart';
import 'package:diplomska_naloga/data/datasources/user_datasource_interface.dart';
import 'package:diplomska_naloga/domain/entities/role.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/exceptions/not_found_exception.dart';
import 'package:diplomska_naloga/domain/exceptions/storage_exception.dart';
import 'package:diplomska_naloga/domain/exceptions/validation_exception.dart';
import 'package:diplomska_naloga/domain/repositories/user_repository.dart';
import 'package:diplomska_naloga/domain/validators/user_validator.dart';

class UserRepositoryImpl implements IUserRepository {
  final IUserDataSource _dataSource;
  final IIdGenerator _idGenerator;
  final IClockService _clock;
  final IUserValidator _validator;
  final ILogger _logger;

  const UserRepositoryImpl({
    required IUserDataSource dataSource,
    required IIdGenerator idGenerator,
    required IClockService clock,
    required IUserValidator validator,
    ILogger? logger,
  }) : _dataSource = dataSource,
       _idGenerator = idGenerator,
       _clock = clock,
       _validator = validator,
       _logger = logger ?? const SilentLogger();

  // ── Write ─────────────────────────────────────────────────────

  @override
  Future<User> createUser({
    required String name,
    required String email,
    required List<String> tags,
  }) async {
    // Throws ValidationException if invalid — propagates as-is to controller
    _validator.validateCreate(name: name, email: email, tags: tags);

    final now = _clock.now();
    final user = User(
      id: _idGenerator.generate(),
      name: name.trim(),
      email: email.trim(),
      role: Role.user,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );

    try {
      return await _dataSource.addUser(user);
    } catch (e, st) {
      _logger.error('createUser failed', e, st);
      throw StorageException('Failed to save user.', cause: e);
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    if (id.trim().isEmpty) {
      throw const ValidationException('Cannot delete a user with empty id.');
    }

    try {
      await _dataSource.deleteUser(id);
      _logger.info('deleteUser: id=$id');
    } on StateError {
      _logger.warning('deleteUser: not found id=$id');
      throw NotFoundException(id);
    } catch (e, st) {
      _logger.error('deleteUser failed', e, st);
      throw StorageException('Failed to delete user.', cause: e);
    }
  }

  @override
  Future<List<User>> filterUsers(String query) async {
    try {
      return await _dataSource.filterUsers(query);
    } catch (e, st) {
      _logger.error('filterUsers failed', e, st);
      throw StorageException('Failed to filter users.', cause: e);
    }
  }

  // ── Read ──────────────────────────────────────────────────────

  @override
  Future<List<User>> getAllUsers({int page = 1, int pageSize = 20}) async {
    try {
      return await _dataSource.getAllUsers(page: page, pageSize: pageSize);
    } catch (e, st) {
      _logger.error('getAllUsers failed', e, st);
      throw StorageException('Failed to load users.', cause: e);
    }
  }

  @override
  Future<User> updateUser(User user) async {
    // Throws ValidationException if invalid — propagates as-is to controller
    _validator.validateUpdate(
      id: user.id,
      name: user.name,
      email: user.email,
      tags: user.tags,
    );

    try {
      return await _dataSource.updateUser(
        user.copyWith(updatedAt: _clock.now()),
      );
    } on StateError {
      _logger.warning('updateUser: not found id=${user.id}');
      throw NotFoundException(user.id);
    } catch (e, st) {
      _logger.error('updateUser failed', e, st);
      throw StorageException('Failed to update user.', cause: e);
    }
  }
}
