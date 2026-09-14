// lib/core/services/benchmark/framework_rebuild_tracker.dart
//
// PURPOSE:
//   Counts widget rebuilds using Flutter's built-in debugOnRebuildDirtyWidget
//   callback — the same mechanism that powers DevTools rebuild stats.
//
// ADVANTAGE OVER RebuildTracker:
//   - No manual increment() calls needed in every widget's build().
//   - Catches ALL widget rebuilds under the tracked subtree.
//   - Per-widget-type breakdown available for analysis.
//   - Framework-level accuracy — no placement ambiguity.
//
// CONSTRAINT:
//   debugOnRebuildDirtyWidget is inside an assert() in the Flutter framework,
//   so it is stripped from profile and release builds. This tracker only
//   works in debug mode. For profile-mode benchmarks, use RebuildTracker.
//
// USAGE:
//   final tracker = FrameworkRebuildTracker();
//   tracker.start();           // hook the callback
//   tracker.reset();           // zero counters before an action
//   // ... action runs, widgets rebuild ...
//   print(tracker.count);      // total rebuilds of tracked widgets
//   print(tracker.breakdown);  // per-widget-type counts
//   print(tracker.log);        // ordered list of every rebuild
//   tracker.stop();            // unhook the callback

import 'package:flutter/widgets.dart';

/// A single rebuild event captured by the framework callback.
class RebuildEvent {
  final String widgetType;
  final bool isFirstBuild;
  final DateTime timestamp;

  /// The widget's key as a string, e.g. `user_abc123` for
  /// `ValueKey<String>('user_abc123')`. Null if no key is set.
  final String? widgetKey;

  /// Depth of the element in the widget tree (root = 0).
  final int depth;

  /// The immediate parent widget's type name.
  final String? parentType;

  /// The widget instance's identity hash code.
  final int widgetHashCode;

  const RebuildEvent({
    required this.widgetType,
    required this.isFirstBuild,
    required this.timestamp,
    this.widgetKey,
    required this.depth,
    this.parentType,
    required this.widgetHashCode,
  });

  @override
  String toString() {
    final tag = isFirstBuild ? 'BUILD' : 'REBUILD';
    final keyStr = widgetKey != null ? ' key=$widgetKey' : '';
    final parentStr = parentType != null ? ' parent=$parentType' : '';
    return '$tag $widgetType$keyStr depth=$depth$parentStr #$widgetHashCode';
  }
}

class FrameworkRebuildTracker {
  /// Widget types to track. If empty, ALL widget rebuilds are counted.
  /// Populate this with the widget types you instrumented with
  /// RebuildTracker.increment() for an apples-to-apples comparison.
  final Set<String> trackedTypes;

  /// When true, only counts re-builds (builtOnce == true), excluding
  /// first-time builds. Set to false to count all builds including initial.
  final bool rebuildsOnly;

  FrameworkRebuildTracker({
    this.trackedTypes = const {},
    this.rebuildsOnly = false,
  });

  // ── State ──────────────────────────────────────────────────────

  int _count = 0;
  final _breakdown = <String, int>{};
  final _log = <RebuildEvent>[];
  bool _active = false;

  /// Total rebuild count since last reset().
  int get count => _count;

  /// Per-widget-type rebuild counts since last reset().
  Map<String, int> get breakdown => Map.unmodifiable(_breakdown);

  /// Ordered list of every rebuild event since last reset().
  List<RebuildEvent> get log => List.unmodifiable(_log);

  /// Whether the callback is currently hooked.
  bool get isActive => _active;

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Hook the framework callback. Call once before running benchmarks.
  void start() {
    assert(() {
      if (_active) return true;
      debugOnRebuildDirtyWidget = _onRebuild;
      _active = true;
      return true;
    }());
  }

  /// Unhook the framework callback.
  void stop() {
    assert(() {
      if (!_active) return true;
      debugOnRebuildDirtyWidget = null;
      _active = false;
      return true;
    }());
  }

  /// Zero all counters. Call before each measured action.
  void reset() {
    _count = 0;
    _breakdown.clear();
    _log.clear();
  }

  // ── Callback ───────────────────────────────────────────────────

  void _onRebuild(Element element, bool builtOnce) {
    // Skip first-time builds if rebuildsOnly is true
    if (rebuildsOnly && !builtOnce) return;

    final typeName = element.widget.runtimeType.toString();

    // Filter by tracked types if specified
    if (trackedTypes.isNotEmpty && !trackedTypes.contains(typeName)) return;

    // Extract widget key — check current element first, then walk up
    // ancestors. Riverpod's ProviderScope holds the ValueKey several
    // levels above the card; ConsumerWidget / WatchingWidget also wrap
    // in keyless inner widgets. Walk up until we find a ValueKey.
    Key? key = element.widget.key;
    if (key == null) {
      element.visitAncestorElements((ancestor) {
        if (ancestor.widget.key is ValueKey) {
          key = ancestor.widget.key;
          return false; // found it, stop
        }
        return true; // keep walking
      });
    }
    String? keyStr;
    if (key is ValueKey) {
      keyStr = '${(key as ValueKey).value}';
    } else if (key != null) {
      keyStr = key.toString();
    }

    // Find immediate parent widget type
    String? parentType;
    element.visitAncestorElements((ancestor) {
      parentType = ancestor.widget.runtimeType.toString();
      return false; // stop after first ancestor
    });

    _count++;
    _breakdown[typeName] = (_breakdown[typeName] ?? 0) + 1;
    _log.add(RebuildEvent(
      widgetType: typeName,
      isFirstBuild: !builtOnce,
      timestamp: DateTime.now(),
      widgetKey: keyStr,
      depth: element.depth,
      parentType: parentType,
      widgetHashCode: element.widget.hashCode,
    ));
  }

  // ── Diagnostics ────────────────────────────────────────────────

  /// Formatted summary for console output.
  String get summary {
    final buf = StringBuffer();
    buf.writeln('  Total: $count rebuilds');
    for (final entry in _breakdown.entries) {
      buf.writeln('    ${entry.key}: ${entry.value}');
    }
    return buf.toString();
  }

  /// Formatted log of every rebuild event.
  String get formattedLog {
    final buf = StringBuffer();
    for (var i = 0; i < _log.length; i++) {
      buf.writeln('  [${i + 1}] ${_log[i]}');
    }
    return buf.toString();
  }
}
