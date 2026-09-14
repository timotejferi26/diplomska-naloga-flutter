// lib/core/benchmark/benchmark_config.dart
//
// PURPOSE:
//   Single source of truth for benchmark run parameters.
//   Mutated from the BenchmarkRunnerScreen at runtime.
//   Read by every component that needs to know dataset size or page size.
//
// SINGLETON PATTERN:
//   Used as a singleton so any class can read the current config
//   without needing it injected. This is appropriate here because
//   it is purely configuration — not business logic.
//
// USED BY:
//   - All four DI setups (to know which datasource size to seed)
//   - BenchmarkHarness (attaches config snapshot to each result)
//   - BenchmarkRunnerScreen (reads and writes datasetSize)
//   - FakeUserGenerator (receives count from here)

class BenchmarkConfig {
  // ── Singleton ─────────────────────────────────────────────────
  static final BenchmarkConfig instance = BenchmarkConfig._();
  BenchmarkConfig._();

  // ── Parameters ────────────────────────────────────────────────

  /// Number of users to seed into the datasource before a benchmark run.
  /// Configurable from the BenchmarkRunnerScreen.
  int datasetSize = 1000;

  /// Number of users returned per page in paginated loads.
  int pageSize = 20;

  /// If true, MetricsExporter writes files automatically after each run.
  bool exportOnCompletion = true;

  /// Fixed seed for FakeUserGenerator — ensures reproducible datasets.
  int generatorSeed = 42;

  // ── Presets ───────────────────────────────────────────────────

  void applyPreset(BenchmarkPreset preset) {
    switch (preset) {
      case BenchmarkPreset.none:
        datasetSize = 0;
        pageSize = 20;
      case BenchmarkPreset.light:
        datasetSize = 100;
        pageSize = 20;
      case BenchmarkPreset.medium:
        datasetSize = 1000;
        pageSize = 20;
      case BenchmarkPreset.heavy:
        datasetSize = 5000;
        pageSize = 50;
      case BenchmarkPreset.stress:
        datasetSize = 10000;
        pageSize = 50;
    }
  }

  @override
  String toString() =>
      'BenchmarkConfig(datasetSize=$datasetSize, pageSize=$pageSize, seed=$generatorSeed)';
}

enum BenchmarkPreset { none, light, medium, heavy, stress }
