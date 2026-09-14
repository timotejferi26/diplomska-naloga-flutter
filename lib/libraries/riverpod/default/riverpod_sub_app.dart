// lib/libraries/riverpod/riverpod_sub_app.dart
//
// Entry point for the Riverpod implementation.
// Wraps everything in ProviderScope and attaches RebuildTracker.

import 'package:diplomska_naloga/core/services/benchmark/benchmark_harness.dart';
import 'package:diplomska_naloga/core/services/benchmark/rebuild_tracker.dart';
import 'package:diplomska_naloga/libraries/riverpod/default/pages/riverpod_user_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiverpodSubApp extends StatelessWidget {
  final VoidCallback onReset;
  const RiverpodSubApp({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: _RiverpodHome(onReset: onReset),
      ),
    );
  }
}

class _RiverpodHome extends StatelessWidget {
  final VoidCallback onReset;
  const _RiverpodHome({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return RebuildTracker(
      child: Builder(
        builder: (ctx) {
          // Register tracker with harness so measure() can read rebuild count
          final tracker = RebuildTracker.of(ctx);
          if (tracker != null) {
            BenchmarkHarness.instance.setTracker(tracker);
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Riverpod'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to menu',
                  onPressed: () {
                    BenchmarkHarness.instance.clearTracker();
                    onReset();
                  },
                ),
              ],
            ),
            body: const RiverpodUserListPage(),
          );
        },
      ),
    );
  }
}
