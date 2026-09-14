// lib/core/benchmark/benchmark_result.dart
//
// PURPOSE:
//   Immutable snapshot of all metrics captured during one measured action.
//   One instance = one call to BenchmarkHarness.measure().
//   Gets collected into a list and eventually written to JSON/CSV.

class BenchmarkResult {
  /// Which library produced this result: 'riverpod' | 'getx' | 'provider' | 'watch_it'
  final String library;

  /// Which action was measured: 'load_N' | 'add_user' | 'edit_user' |
  /// 'delete_user' | 'search_query' | 'search_clear' | 'page_next' | 'ttfr'
  final String event;

  /// RSS delta in KB — memory after action minus memory before.
  /// Positive = memory grew. Negative = GC ran during the action.
  final int rssDeltaKB;

  /// Wall-clock duration from action start to first settled frame, in ms.
  final int durationMs;

  /// Number of widget build() calls triggered by this action.
  final int rebuildCount;

  /// Worst single frame duration during this action in ms.
  /// Anything above 16.7ms = dropped frame at 60fps.
  final double worstFrameMs;

  /// Dataset size at the time of measurement — from BenchmarkConfig.
  final int datasetSize;

  /// When this result was recorded.
  final DateTime timestamp;

  const BenchmarkResult({
    required this.library,
    required this.event,
    required this.rssDeltaKB,
    required this.durationMs,
    required this.rebuildCount,
    required this.worstFrameMs,
    required this.datasetSize,
    required this.timestamp,
  });

  // ── Serialisation ─────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'library': library,
    'event': event,
    'rss_delta_kb': rssDeltaKB,
    'duration_ms': durationMs,
    'rebuild_count': rebuildCount,
    'worst_frame_ms': worstFrameMs,
    'dataset_size': datasetSize,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Single CSV row — column order must match MetricsExporter header.
  String toCsvRow() =>
      '$library,$event,$rssDeltaKB,$durationMs,$rebuildCount,'
      '${worstFrameMs.toStringAsFixed(2)},$datasetSize,${timestamp.toIso8601String()}';

  @override
  String toString() =>
      'BenchmarkResult(lib=$library, event=$event, '
      'rss=${rssDeltaKB}KB, dur=${durationMs}ms, '
      'rebuilds=$rebuildCount, frame=${worstFrameMs.toStringAsFixed(1)}ms)';
}
