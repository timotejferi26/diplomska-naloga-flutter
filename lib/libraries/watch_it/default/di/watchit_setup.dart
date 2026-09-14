// lib/libraries/watch_it/di/watchit_setup.dart
//
// Registers all dependencies into get_it's service locator.
// ViewModel registered as a factory — fresh instance per navigation.
// Called once before WatchItSubApp mounts.

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/libraries/watch_it/default/view_models/watchit_user_view_model.dart';
import 'package:watch_it/watch_it.dart';

final _getIt = GetIt.instance;

void setupWatchItDependencies() {
  // Avoid re-registering if already set up (hot restart safety)
  if (_getIt.isRegistered<WatchItUserViewModel>()) return;

  final useCases = SharedDependencies.build(benchmarkMode: true);

  _getIt.registerLazySingleton<WatchItUserViewModel>(
    () => WatchItUserViewModel(useCases: useCases),
  );
}

void teardownWatchItDependencies() {
  if (_getIt.isRegistered<WatchItUserViewModel>()) {
    _getIt.unregister<WatchItUserViewModel>();
  }
}
