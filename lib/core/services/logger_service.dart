// lib/core/services/logger_service.dart
//
// PURPOSE:
//   Structured logging abstraction. Every layer that needs to log
//   depends on ILogger, never on print() or dart:developer directly.
//
// IMPLEMENTATIONS:
//   - ConsoleLogger    : prints to stdout — used in dev/debug
//   - SilentLogger     : discards everything — used in benchmark runs
//                        so logging overhead doesn't skew timing results
//   - BenchmarkLogger  : stores log entries in memory for later inspection
//
// USED BY:
//   - UserLocalDataSource (logs CRUD operations)
//   - UserRepositoryImpl (could log failures)
//   - BenchmarkHarness (logs metric snapshots)
//   - All library controllers/notifiers (optional)

abstract class ILogger {
  void info(String message);
  void warning(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

// ── Console ───────────────────────────────────────────────────────────────

/// Prints structured log lines to stdout.
/// Use in development and debug builds.
class ConsoleLogger implements ILogger {
  const ConsoleLogger();

  @override
  void info(String message) => print('[INFO]  $message');

  @override
  void warning(String message) => print('[WARN]  $message');

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('[ERROR] $message');
    if (error != null) print('        ↳ $error');
    if (stackTrace != null) print('        ↳ $stackTrace');
  }
}

// ── Silent ────────────────────────────────────────────────────────────────

/// Discards all log messages.
/// Use during benchmark runs to eliminate logging overhead from timing results.
class SilentLogger implements ILogger {
  const SilentLogger();

  @override
  void info(String message) {}

  @override
  void warning(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

// ── In-memory (for tests) ─────────────────────────────────────────────────

/// Stores log entries in a list. Use in unit tests to assert on log output.
class InMemoryLogger implements ILogger {
  final List<LogEntry> entries = [];

  @override
  void info(String message) => entries.add(LogEntry(LogLevel.info, message));

  @override
  void warning(String message) =>
      entries.add(LogEntry(LogLevel.warning, message));

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      entries.add(LogEntry(LogLevel.error, message, error: error));

  List<LogEntry> get infos =>
      entries.where((e) => e.level == LogLevel.info).toList();
  List<LogEntry> get warnings =>
      entries.where((e) => e.level == LogLevel.warning).toList();
  List<LogEntry> get errors =>
      entries.where((e) => e.level == LogLevel.error).toList();

  void clear() => entries.clear();
}

enum LogLevel { info, warning, error }

class LogEntry {
  final LogLevel level;
  final String message;
  final Object? error;
  final DateTime timestamp;

  LogEntry(this.level, this.message, {this.error}) : timestamp = DateTime.now();

  @override
  String toString() => '[${level.name.toUpperCase()}] $message';
}
