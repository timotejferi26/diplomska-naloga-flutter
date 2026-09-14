// lib/core/services/clock_service.dart
//
// PURPOSE:
//   Abstracts DateTime.now() so that UserRepositoryImpl can be tested
//   with a fixed, deterministic timestamp instead of the real system clock.
//
// USED BY:
//   - UserRepositoryImpl (sets createdAt and updatedAt)
//   - Tests (FixedClockService produces a predictable DateTime)

abstract class IClockService {
  DateTime now();
}

/// Production implementation — delegates to DateTime.now().
class SystemClockService implements IClockService {
  const SystemClockService();

  @override
  DateTime now() => DateTime.now();
}

/// Test/benchmark implementation — always returns a fixed time.
/// Use this when seeding fake data so timestamps are deterministic.
class FixedClockService implements IClockService {
  final DateTime _fixed;

  const FixedClockService(this._fixed);

  /// Convenience: fixed at 2024-01-15 10:00:00 UTC
  factory FixedClockService.benchmark() =>
      FixedClockService(DateTime.parse('2024-01-15T10:00:00Z'));

  @override
  DateTime now() => _fixed;
}
