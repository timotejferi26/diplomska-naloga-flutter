// lib/core/services/id_generator.dart
//
// PURPOSE:
//   Abstracts UUID generation so that UserRepositoryImpl can be tested
//   with predictable IDs (e.g. 'user-1', 'user-2') instead of random UUIDs.
//
// USED BY:
//   - UserRepositoryImpl (assigns id on createUser)
//   - FakeUserGenerator (assigns ids when seeding data)
//   - Tests (SequentialIdGenerator produces 'id-1', 'id-2', ...)

import 'package:uuid/uuid.dart';

abstract class IIdGenerator {
  String generate();
}

/// Production implementation — generates a UUID v4.
class UuidGenerator implements IIdGenerator {
  final Uuid _uuid;

  UuidGenerator() : _uuid = const Uuid();

  @override
  String generate() => _uuid.v4();
}

/// Test/benchmark implementation — produces sequential IDs.
/// Useful when you want predictable, readable IDs in test output.
class SequentialIdGenerator implements IIdGenerator {
  final String _prefix;
  int _counter;

  SequentialIdGenerator({String prefix = 'user', int startAt = 1})
    : _prefix = prefix,
      _counter = startAt;

  @override
  String generate() => '$_prefix-${_counter++}';

  void reset() => _counter = 1;
}
