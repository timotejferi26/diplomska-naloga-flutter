// lib/libraries/getx/getx_sub_app.dart
//
// Uses GetMaterialApp so Get's routing and service locator work.
// Binding wires all dependencies before the page mounts.

import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show BenchmarkHarness, RebuildTracker;
import 'package:diplomska_naloga/libraries/getx/advanced/bindings/getx_user_binding.dart';
import 'package:diplomska_naloga/libraries/getx/advanced/pages/getx_user_list_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GetXSubApp extends StatelessWidget {
  final VoidCallback onReset;
  const GetXSubApp({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      initialBinding: GetXUserBinding(),
      home: RebuildTracker(
        child: Builder(
          builder: (ctx) {
            final tracker = RebuildTracker.of(ctx);
            if (tracker != null) {
              BenchmarkHarness.instance.setTracker(tracker);
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text('GetX'),
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
              body: const GetXUserListPage(),
            );
          },
        ),
      ),
    );
  }
}
