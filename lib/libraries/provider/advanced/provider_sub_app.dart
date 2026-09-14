// lib/libraries/provider/provider_sub_app.dart

import 'package:diplomska_naloga/core/services/benchmark/index.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/di/provider_injector.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/pages/provider_user_list_page.dart';
import 'package:flutter/material.dart';

class ProviderSubApp extends StatelessWidget {
  final VoidCallback onReset;
  const ProviderSubApp({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return providerSubAppProviders(
      child: MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        home: RebuildTracker(
          child: Builder(
            builder: (ctx) {
              final tracker = RebuildTracker.of(ctx);
              if (tracker != null) {
                BenchmarkHarness.instance.setTracker(tracker);
              }
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Provider'),
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
                body: const ProviderUserListPage(),
              );
            },
          ),
        ),
      ),
    );
  }
}
