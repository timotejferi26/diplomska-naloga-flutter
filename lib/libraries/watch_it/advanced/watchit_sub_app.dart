// lib/libraries/watch_it/watchit_sub_app.dart
//
// Calls setupWatchItDependencies() before mounting so get_it is ready.
// Tears down on back so the next run gets a fresh ViewModel.

import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show RebuildTracker, BenchmarkHarness;
import 'package:diplomska_naloga/libraries/watch_it/advanced/di/watchit_setup.dart';
import 'package:diplomska_naloga/libraries/watch_it/advanced/pages/watchit_user_list_page.dart';
import 'package:flutter/material.dart';

class WatchItSubApp extends StatefulWidget {
  final VoidCallback onReset;
  const WatchItSubApp({super.key, required this.onReset});

  @override
  State<WatchItSubApp> createState() => _WatchItSubAppState();
}

class _WatchItSubAppState extends State<WatchItSubApp> {
  @override
  void initState() {
    super.initState();
    setupWatchItDependencies();
  }

  @override
  void dispose() {
    teardownWatchItDependencies();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: RebuildTracker(
        child: Builder(
          builder: (ctx) {
            final tracker = RebuildTracker.of(ctx);
            if (tracker != null) {
              BenchmarkHarness.instance.setTracker(tracker);
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text('watch_it'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to menu',
                    onPressed: () {
                      BenchmarkHarness.instance.clearTracker();
                      widget.onReset();
                    },
                  ),
                ],
              ),
              body: const WatchItUserListPage(),
            );
          },
        ),
      ),
    );
  }
}
