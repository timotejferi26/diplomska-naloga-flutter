// lib/core/benchmark/rebuild_tracker.dart
//
// PURPOSE:
//   Counts widget build() calls beneath it in the tree.
//   Wrap the root of each library's page with RebuildTracker to
//   measure how many widgets rebuild per action.
//
// HOW THE COUNTER WORKS:
//   InheritedWidget itself is immutable, so it can't hold a mutable int.
//   Instead it holds a _Counter object — a plain mutable class.
//   Mutating _Counter doesn't trigger updateShouldNotify, so incrementing
//   the counter never causes extra rebuilds. Clean separation.
//
// USAGE — wrap the page root:
//   RebuildTracker(child: RiverpodUsersListPage())
//
// USAGE — increment from any widget's build():
//   RebuildTracker.of(context).increment();
//
// USAGE — read and reset from BenchmarkHarness:
//   final count = _tracker.count;
//   _tracker.reset();
//
// CAVEAT — SCROLL CHURN INFLATES THE COUNT:
//   ListView.builder is lazy: when a card scrolls out of viewport its
//   Element is disposed; when it scrolls back in, a fresh Element is
//   created and build() runs again. The tracker cannot distinguish
//   "rebuilt due to state change" from "first build of a freshly-mounted
//   element after scroll churn".
//
//   In practice this means: manual fast up/down scrolling on a device
//   will produce inflated counts (the same key appearing multiple times
//   in the log as the card leaves and re-enters the viewport). This is
//   NOT a state-management problem — all four libraries exhibit it
//   under the same fling pattern.
//
//   The integration test (default_benchmark_test.dart or advanced_benchmark_test.dart) uses tester.fling()
//   with a controlled velocity for load_page_2 / load_page_3, so the
//   recorded benchmark numbers are reproducible. Hand-driven debug
//   sessions are not.

import 'package:flutter/widgets.dart';
import 'package:diplomska_naloga/core/services/logger_service.dart';

class RebuildTracker extends InheritedWidget {
  final _Counter _counter = _Counter();
  final _logger = ConsoleLogger();

  RebuildTracker({super.key, required super.child});

  /// Access the nearest RebuildTracker in the tree.
  static RebuildTracker? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RebuildTracker>();

  /// Call this at the top of any build() you want counted.
  /// Pass the widget's [BuildContext] to log detailed rebuild info.
  void increment(BuildContext context) {
    _counter.count++;

    final element = context as Element;
    final widget = element.widget;
    final typeName = widget.runtimeType.toString();

    // Extract key — check current widget first, then walk up ancestors.
    // Riverpod's ProviderScope holds the ValueKey several levels above
    // the card's inner element; ConsumerWidget / WatchingWidget also
    // wrap in keyless inner widgets. Walk up until we find a ValueKey.
    Key? key = widget.key;
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
      return false;
    });

    final keyInfo = keyStr != null ? ' key=$keyStr' : '';
    final parentInfo = parentType != null ? ' parent=$parentType' : '';
    _logger.info(
      'Build count incremented: #${_counter.count}: $typeName$keyInfo'
      ' depth=${element.depth}$parentInfo'
      ' #${widget.hashCode}',
    );
  }

  /// Total build() calls since last reset().
  int get count => _counter.count;

  /// Zero the counter before starting a new measurement.
  void reset() => _counter.count = 0;

  /// Never notify — the counter is side-effect data, not widget state.
  @override
  bool updateShouldNotify(RebuildTracker oldWidget) => false;
}

/// Mutable counter held by RebuildTracker.
/// Lives outside the InheritedWidget so it can be mutated freely.
class _Counter {
  int count = 0;
}
