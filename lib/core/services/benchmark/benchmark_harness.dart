// lib/core/benchmark/benchmark_harness.dart
//
// PURPOSE:
//   Central coordinator. One public method: measure().
//   Wraps any async action, orchestrates all four samplers,
//   and stores the resulting BenchmarkResult.
//
// SINGLETON:
//   Access via BenchmarkHarness.instance from anywhere.
//   All four libraries write to the same result list so
//   MetricsExporter can export all results in one shot.
//
// USAGE — in any controller/notifier:
//   await BenchmarkHarness.instance.measure(
//     event:   'add_user',
//     library: 'riverpod',
//     action:  () => notifier.addUser(params),
//   );
//
// IMPORTANT:
//   measure() must be called from the UI isolate (main thread).
//   SchedulerBinding and ProcessInfo are both main-isolate only.

import 'package:flutter/foundation.dart';

import 'package:diplomska_naloga/core/services/benchmark/benchmark_config.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_result.dart';
import 'package:diplomska_naloga/core/services/benchmark/frame_timer.dart';
import 'package:diplomska_naloga/core/services/benchmark/framework_rebuild_tracker.dart';
import 'package:diplomska_naloga/core/services/benchmark/memory_sampler.dart';
import 'package:diplomska_naloga/core/services/benchmark/rebuild_tracker.dart';

class BenchmarkHarness {
  // ── Singleton ─────────────────────────────────────────────────
  static final BenchmarkHarness instance = BenchmarkHarness._();
  BenchmarkHarness._();

  // ── Internal components ───────────────────────────────────────
  final _memory = const MemorySampler();
  final _frame = FrameTimer();
  final _results = <BenchmarkResult>[];

  // Controllers use the benchmark harness directly so production measurements
  // include the complete state transition. Unit tests, however, exercise those
  // controllers without a Flutter frame pipeline. Disabling instrumentation in
  // tests keeps the action itself unchanged while avoiding frame and RSS work.
  bool _measurementsEnabled = true;

  @visibleForTesting
  void setMeasurementsEnabled(bool enabled) {
    _measurementsEnabled = enabled;
  }

  // Optional RebuildTracker — set by each library's root widget
  RebuildTracker? _tracker;

  // Optional FrameworkRebuildTracker — uses debugOnRebuildDirtyWidget.
  // Only works in debug mode. When set, its count is preferred over
  // the manual RebuildTracker.
  FrameworkRebuildTracker? _frameworkTracker;

  /// All results collected so far across all libraries and events.
  List<BenchmarkResult> get results => List.unmodifiable(_results);

  /// Register the active RebuildTracker before a run starts.
  /// Each library's sub-app calls this when it mounts.
  void setTracker(RebuildTracker tracker) => _tracker = tracker;

  /// Clear the tracker reference when a sub-app unmounts.
  void clearTracker() => _tracker = null;

  /// Register a FrameworkRebuildTracker for debug-mode benchmarks.
  /// When set, rebuild counts come from the framework callback and
  /// per-widget breakdown is available via [lastBreakdown].
  void setFrameworkTracker(FrameworkRebuildTracker tracker) {
    _frameworkTracker = tracker;
    tracker.start();
  }

  /// Clear the framework tracker reference.
  void clearFrameworkTracker() {
    _frameworkTracker?.stop();
    _frameworkTracker = null;
  }

  /// Per-widget-type rebuild breakdown from the last measurement.
  /// Only available when a FrameworkRebuildTracker is attached.
  Map<String, int> get lastBreakdown =>
      _frameworkTracker?.breakdown ?? const {};

  /// Ordered log of every rebuild from the last measurement.
  /// Only available when a FrameworkRebuildTracker is attached.
  List<RebuildEvent> get lastLog => _frameworkTracker?.log ?? const [];

  // ── Core API ──────────────────────────────────────────────────

  /// Measures [action] and stores one BenchmarkResult.
  ///
  /// [event]   — identifier for what is being measured, e.g. 'add_user'
  /// [library] — which library is being tested, e.g. 'riverpod'
  /// [action]  — the async operation to measure
  Future<T> measure<T>({
    required String event,
    required String library,
    required Future<T> Function() action,
  }) async {
    if (!_measurementsEnabled) {
      return action();
    }

    // 1. Snapshot state before
    final memBefore = _memory.sample();
    final timeBefore = DateTime.now();
    _tracker?.reset();
    _frameworkTracker?.reset();
    _frame.startTracking();

    // 2. Run the action
    final result = await action();

    // 3. Wait for the UI to settle (one full frame after state change).
    //    This is the end of the user-visible measurement window.
    await _frame.awaitSettledFrame();

    // 4. Snapshot state after — captured BEFORE flushTimings so the
    //    120ms FrameTiming-delivery grace period doesn't inflate durationMs.
    final durationMs = DateTime.now().difference(timeBefore).inMilliseconds;
    final memAfter = _memory.sample();

    // 5. Wait for the engine to deliver pending FrameTiming callbacks
    //    for frames produced during the measurement window.
    await _frame.flushTimings();

    // 6. Capture rebuild count and breakdown.
    // The framework tracker only works in debug mode (its start() is inside
    // an assert() that's stripped in profile/release). When it's set but
    // not active, fall through to the manual tracker.
    final useFramework =
        _frameworkTracker != null && _frameworkTracker!.isActive;
    final rebuildCount = useFramework
        ? _frameworkTracker!.count
        : (_tracker?.count ?? -1);

    // 7. Log per-widget breakdown if framework tracker is active
    if (_frameworkTracker != null && _frameworkTracker!.isActive) {
      final bd = _frameworkTracker!.breakdown;
      final log = _frameworkTracker!.log;
      debugPrint('  [$library/$event] rebuilds=$rebuildCount $bd');
      for (final entry in log) {
        debugPrint('    $entry');
      }
    }

    // 8. Store result
    _results.add(
      BenchmarkResult(
        library: library,
        event: event,
        rssDeltaKB: _memory.delta(memBefore, memAfter),
        durationMs: durationMs,
        rebuildCount: rebuildCount,
        worstFrameMs: _frame.worstFrameMs,
        datasetSize: BenchmarkConfig.instance.datasetSize,
        timestamp: DateTime.now(),
      ),
    );

    return result;
  }

  /// Clears all stored results. Call before starting a fresh benchmark run.
  void clear() => _results.clear();

  /// Returns only results for a specific library.
  List<BenchmarkResult> resultsFor(String library) =>
      _results.where((r) => r.library == library).toList();

  /// Returns only results for a specific event across all libraries.
  List<BenchmarkResult> resultsForEvent(String event) =>
      _results.where((r) => r.event == event).toList();
}
