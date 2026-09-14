// lib/libraries/provider/di/provider_injector.dart
//
// Builds the provider tree via SharedDependencies.
// Uses a single ChangeNotifierProvider since the notifier owns all state.

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/libraries/provider/default/notifiers/provider_user_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget providerSubAppProviders({required Widget child}) {
  final useCases = SharedDependencies.build(benchmarkMode: true);
  return ChangeNotifierProvider(
    create: (_) => ProviderUserNotifier(useCases: useCases),
    child: child,
  );
}
