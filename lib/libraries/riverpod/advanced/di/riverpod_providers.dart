// lib/libraries/riverpod/di/riverpod_providers.dart
//
// All Riverpod providers for the user feature.
// Services and repository are built once via SharedDependencies.
// The notifier is an AsyncNotifier — modern Riverpod 2.x pattern.

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/riverpod/advanced/notifiers/user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Single use-case bundle — built once, shared by all providers in this scope.
final _useCasesProvider = Provider<UserUseCases>(
  (_) => SharedDependencies.build(benchmarkMode: true),
);

// The main notifier — holds AsyncValue<List<User>> as state.
final userNotifierProvider = AsyncNotifierProvider<UserNotifier, List<User>>(
  () => UserNotifier(),
);

// Per-item provider — overridden via ProviderScope in the list builder.
// Lets each card watch only its own user, not the full list.
final userItemProvider = Provider<User>(
  (_) => throw UnimplementedError('must be overridden via ProviderScope'),
);

// Expose use cases to the notifier.
final useCasesProvider = _useCasesProvider;
