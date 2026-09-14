// lib/core/benchmark/metrics_exporter.dart
//
// PURPOSE:
//   Writes collected BenchmarkResults to the app's documents directory.
//   Produces two files per export:
//     benchmark_YYYY-MM-DD_HH-MM-SS.json  — full fidelity, all fields
//     benchmark_YYYY-MM-DD_HH-MM-SS.csv   — for spreadsheet analysis
//
// DEPENDENCIES:
//   path_provider — to locate the documents directory on device
//   dart:io       — File write
//   dart:convert  — jsonEncode
//
// CALLED BY:
//   BenchmarkRunnerScreen when user taps the export button.

// lib/core/benchmark/metrics_exporter.dart
//
// Writes benchmark results to /sdcard/Download so they are immediately
// accessible via `adb pull` without needing run-as or root.
// Also writes to the app documents dir as a backup.

import 'dart:convert';
import 'dart:io';

import 'package:diplomska_naloga/core/services/benchmark/benchmark_result.dart';
import 'package:path_provider/path_provider.dart';

class MetricsExporter {
  const MetricsExporter();

  static const _csvHeader =
      'library,event,rss_delta_kb,duration_ms,rebuild_count,worst_frame_ms,dataset_size,timestamp';

  /// Exports [results] to JSON and CSV.
  /// Writes to /sdcard/Download (readable via `adb pull`) AND to the
  /// app documents directory as a fallback.
  /// Returns the path that was written to.
  Future<String> exportAll(List<BenchmarkResult> results) async {
    if (results.isEmpty) throw StateError('No results to export.');

    final timestamp = _fileTimestamp();
    final jsonContent = jsonEncode(results.map((r) => r.toJson()).toList());
    final csvContent = [
      _csvHeader,
      ...results.map((r) => r.toCsvRow()),
    ].join('\n');

    // ── Primary: write to Downloads (adb pull /sdcard/Download/benchmark_*.csv)
    final downloads = Directory('/sdcard/Download');
    if (await downloads.exists()) {
      await File(
        '${downloads.path}/benchmark_$timestamp.json',
      ).writeAsString(jsonContent);
      await File(
        '${downloads.path}/benchmark_$timestamp.csv',
      ).writeAsString(csvContent);
      return downloads.path;
    }

    // ── Fallback: app documents directory
    final docs = await getApplicationDocumentsDirectory();
    await File(
      '${docs.path}/benchmark_$timestamp.json',
    ).writeAsString(jsonContent);
    await File(
      '${docs.path}/benchmark_$timestamp.csv',
    ).writeAsString(csvContent);
    return docs.path;
  }

  String _fileTimestamp() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';
  }
}
