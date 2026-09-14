// lib/core/benchmark/memory_sampler.dart
//
// PURPOSE:
//   Reads current process memory via ProcessInfo.currentRss.
//   Called before and after each action — the delta is stored in BenchmarkResult.
//
// NOTE ON RSS vs HEAP:
//   currentRss = entire process memory (code + stack + heap + shared libs).
//   It's not heap-only, but it's available in release builds without --observe.
//   For comparing libraries against each other it's consistent enough —
//   the code/stack portions are constant across all four libraries.

import 'dart:io';

class MemorySampler {
  const MemorySampler();

  /// Returns current RSS in KB.
  int sample() => ProcessInfo.currentRss ~/ 1024;

  /// Returns the delta in KB between two samples.
  /// Positive = memory grew. Negative = GC ran between samples.
  int delta(int before, int after) => after - before;
}
