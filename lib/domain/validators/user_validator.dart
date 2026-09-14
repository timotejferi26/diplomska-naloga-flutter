// lib/domain/validators/user_validator.dart
//
// PURPOSE:
//   Validates user input before any storage operation.
//   The abstract interface allows swapping implementations in tests
//   (e.g. a PermissiveValidator that accepts anything for benchmark seeding).
//
// USED BY:
//   - UserRepositoryImpl (injected via constructor)
//   - Tests (MockUserValidator for unit testing repos in isolation)
//
// RULES:
//   ✅ Pure Dart — no Flutter or package imports
//   ✅ Throws ValidationException on failure (repo catches and wraps it)
//   ✅ Returns void on success (no return value needed)

import 'package:diplomska_naloga/domain/exceptions/validation_exception.dart';

// ── Interface ─────────────────────────────────────────────────────────────
abstract class IUserValidator {
  /// Validates fields for a new user creation.
  /// Throws [ValidationException] if any field is invalid.
  void validateCreate({
    required String name,
    required String email,
    required List<String> tags,
  });

  /// Validates fields for an update operation.
  /// Throws [ValidationException] if any field is invalid.
  void validateUpdate({
    required String id,
    required String name,
    required String email,
    required List<String> tags,
  });
}

// ── Default implementation ────────────────────────────────────────────────

class DefaultUserValidator implements IUserValidator {
  const DefaultUserValidator();

  @override
  void validateCreate({
    required String name,
    required String email,
    required List<String> tags,
  }) {
    _validateName(name);
    _validateEmail(email);
    _validateTags(tags);
  }

  @override
  void validateUpdate({
    required String id,
    required String name,
    required String email,
    required List<String> tags,
  }) {
    if (id.trim().isEmpty) {
      throw const ValidationException('User ID must not be empty.');
    }
    _validateName(name);
    _validateEmail(email);
    _validateTags(tags);
  }

  // ── Private helpers ──────────────────────────────────────────

  void _validateName(String name) {
    if (name.trim().isEmpty) {
      throw const ValidationException('Name must not be empty.');
    }
    if (name.trim().length < 2) {
      throw const ValidationException('Name must be at least 2 characters.');
    }
    if (name.trim().length > 100) {
      throw const ValidationException('Name must be 100 characters or fewer.');
    }
  }

  void _validateEmail(String email) {
    if (email.trim().isEmpty) {
      throw const ValidationException('Email must not be empty.');
    }
    // Generated benchmark users can contain Slovenian letters in the local
    // part (for example, "tomaž.kovač@example.com"). Keep the domain check
    // ASCII-based, but accept non-whitespace Unicode characters before @.
    final emailRegex = RegExp(
      r'^[^\s@]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
      unicode: true,
    );
    if (!emailRegex.hasMatch(email.trim())) {
      throw const ValidationException('Email address is not valid.');
    }
  }

  void _validateTags(List<String> tags) {
    if (tags.length > 5) {
      throw const ValidationException('A user can have at most 5 tags.');
    }
    for (final tag in tags) {
      if (tag.trim().isEmpty) {
        throw const ValidationException('Tags must not be empty strings.');
      }
      if (tag.trim().length > 30) {
        throw const ValidationException(
          'Each tag must be 30 characters or fewer.',
        );
      }
    }
  }
}

// ── Test helper — accepts anything, used for benchmark seeding ────────────

/// A validator that never throws. Use this when seeding fake data in tests
/// or benchmarks where you don't want validation to interfere.
class PermissiveUserValidator implements IUserValidator {
  const PermissiveUserValidator();

  @override
  void validateCreate({
    required String name,
    required String email,
    required List<String> tags,
  }) {
    // intentionally no-op
  }

  @override
  void validateUpdate({
    required String id,
    required String name,
    required String email,
    required List<String> tags,
  }) {
    // intentionally no-op
  }
}
