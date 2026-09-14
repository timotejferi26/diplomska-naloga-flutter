import 'dart:async';

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_config.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_harness.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/getx/advanced/controllers/getx_user_controller.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/notifiers/provider_user_notifier.dart';
import 'package:diplomska_naloga/libraries/riverpod/advanced/di/riverpod_providers.dart';
import 'package:diplomska_naloga/libraries/riverpod/advanced/notifiers/user_notifier.dart';
import 'package:diplomska_naloga/libraries/watch_it/advanced/view_models/watchit_user_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:watch_it/watch_it.dart';

import '../support/fake_user_repository.dart';

// Unit-level contracts for state objects with substituted dependencies. These
// do not mount widgets or exercise production bindings, routes or DI scopes.
// Provider uses constructor injection, Riverpod overrides its provider, and
// GetX/Watch_It use test registrations with the production registration pattern.
const _initializationTimeout = Duration(seconds: 5);

Future<void> _waitForListenable(
  Listenable source,
  bool Function() isReady,
) async {
  final ready = Completer<void>();
  void check() {
    if (isReady() && !ready.isCompleted) ready.complete();
  }

  source.addListener(check);
  try {
    check();
    await ready.future.timeout(_initializationTimeout);
  } finally {
    source.removeListener(check);
  }
}

Future<void> _waitForStream(
  Stream<bool> source,
  bool Function() isReady,
) async {
  final ready = Completer<void>();
  void check() {
    if (isReady() && !ready.isCompleted) ready.complete();
  }

  final subscription = source.listen((_) => check());
  try {
    check();
    await ready.future.timeout(_initializationTimeout);
  } finally {
    await subscription.cancel();
  }
}

abstract class UserStateAdapter {
  UserStateAdapter(this.useCases);

  final UserUseCases useCases;
  bool _disposed = false;

  Future<void> initialize();

  List<User> get users;

  Future<String?> addUser({
    required String name,
    required String email,
    required List<String> tags,
  });

  Future<String?> updateUser(User user);

  Future<void> deleteUser(String id);

  Future<void> search(String query);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disposeState();
  }

  Future<void> disposeState();
}

class ProviderStateAdapter extends UserStateAdapter {
  ProviderStateAdapter(super.useCases);

  late final ProviderUserNotifier _notifier;

  @override
  Future<void> initialize() async {
    _notifier = ProviderUserNotifier(useCases: useCases);
    // The constructor has already started the initial request.
    await _waitForListenable(_notifier, () => !_notifier.isLoading);
    expect(_notifier.error, isNull);
  }

  @override
  List<User> get users => _notifier.users;

  @override
  Future<String?> addUser({
    required String name,
    required String email,
    required List<String> tags,
  }) => _notifier.addUser(name: name, email: email, tags: tags);

  @override
  Future<String?> updateUser(User user) => _notifier.updateUser(user);

  @override
  Future<void> deleteUser(String id) => _notifier.deleteUser(id);

  @override
  Future<void> search(String query) => _notifier.search(query);

  @override
  Future<void> disposeState() async => _notifier.dispose();
}

class RiverpodStateAdapter extends UserStateAdapter {
  RiverpodStateAdapter(super.useCases);

  late final ProviderContainer _container;
  late final UserNotifier _notifier;

  @override
  Future<void> initialize() async {
    _container = ProviderContainer(
      overrides: [useCasesProvider.overrideWithValue(useCases)],
    );
    await _container
        .read(userNotifierProvider.future)
        .timeout(_initializationTimeout);
    _notifier = _container.read(userNotifierProvider.notifier);
  }

  @override
  List<User> get users =>
      _container.read(userNotifierProvider).value ?? const [];

  @override
  Future<String?> addUser({
    required String name,
    required String email,
    required List<String> tags,
  }) => _notifier.addUser(name: name, email: email, tags: tags);

  @override
  Future<String?> updateUser(User user) => _notifier.updateUser(user);

  @override
  Future<void> deleteUser(String id) => _notifier.deleteUser(id);

  @override
  Future<void> search(String query) => _notifier.search(query);

  @override
  Future<void> disposeState() async => _container.dispose();
}

class GetXStateAdapter extends UserStateAdapter {
  GetXStateAdapter(super.useCases);

  late final GetXUserController _controller;

  @override
  Future<void> initialize() async {
    Get.reset();
    Get.testMode = true;
    Get.put<UserUseCases>(useCases);
    Get.lazyPut<GetXUserController>(
      () => GetXUserController(useCases: Get.find<UserUseCases>()),
    );
    _controller = Get.find<GetXUserController>();
    // Get.find starts onInit(), which already calls loadUsers().
    await _waitForStream(
      _controller.isLoading.stream,
      () => !_controller.isLoading.value,
    );
    expect(_controller.error.value, isNull);
  }

  @override
  List<User> get users =>
      _controller.order.map((id) => _controller.userById(id)!.value).toList();

  @override
  Future<String?> addUser({
    required String name,
    required String email,
    required List<String> tags,
  }) => _controller.addUser(name: name, email: email, tags: tags);

  @override
  Future<String?> updateUser(User user) => _controller.updateUser(user);

  @override
  Future<void> deleteUser(String id) => _controller.deleteUser(id);

  @override
  Future<void> search(String query) => _controller.search(query);

  @override
  Future<void> disposeState() async {
    // reset() alone removes registrations but does not call onClose().
    await Get.delete<GetXUserController>(force: true);
    Get.reset();
  }
}

class WatchItStateAdapter extends UserStateAdapter {
  WatchItStateAdapter(super.useCases);

  final GetIt _getIt = GetIt.instance;
  late final WatchItUserViewModel _viewModel;

  @override
  Future<void> initialize() async {
    await _getIt.reset();
    _getIt.registerLazySingleton<WatchItUserViewModel>(
      () => WatchItUserViewModel(useCases: useCases),
    );
    _viewModel = _getIt<WatchItUserViewModel>();
    await _waitForListenable(
      _viewModel.isLoading,
      () => !_viewModel.isLoading.value,
    );
    expect(_viewModel.error.value, isNull);
  }

  @override
  List<User> get users => _viewModel.order.value
      .map((id) => _viewModel.listenableFor(id).value)
      .toList();

  @override
  Future<String?> addUser({
    required String name,
    required String email,
    required List<String> tags,
  }) => _viewModel.addUser(name: name, email: email, tags: tags);

  @override
  Future<String?> updateUser(User user) => _viewModel.updateUser(user);

  @override
  Future<void> deleteUser(String id) => _viewModel.deleteUser(id);

  @override
  Future<void> search(String query) => _viewModel.search(query);

  @override
  Future<void> disposeState() => _getIt.reset();
}

typedef AdapterFactory = UserStateAdapter Function(UserUseCases useCases);

void runStateManagementContract(AdapterFactory createAdapter) {
  Future<UserStateAdapter> start(FakeUserRepository repository) async {
    final adapter = createAdapter(buildTestUseCases(repository: repository));
    // Register cleanup before awaiting initialization so failures also clean up.
    addTearDown(adapter.dispose);
    await adapter.initialize();
    return adapter;
  }

  group('state management with an injected repository', () {
    late UserStateAdapter adapter;
    late FakeUserRepository repository;

    setUp(() async {
      repository = FakeUserRepository();
      adapter = await start(repository);
    });

    test('loads the initial users exactly once through the dependency', () {
      expect(adapter.users.map((user) => user.id), ['user-1', 'user-2']);
      expect(repository.getAllUsersCalls, [(page: 1, pageSize: 20)]);
    });

    test('adds a user at the beginning of the state', () async {
      final error = await adapter.addUser(
        name: 'Cvetka Zupan',
        email: 'cvetka@example.com',
        tags: const ['nova'],
      );

      expect(error, isNull);
      expect(adapter.users, hasLength(3));
      expect(adapter.users.first.name, 'Cvetka Zupan');
      expect(repository.createdUsers, hasLength(1));
      final request = repository.createdUsers.single;
      expect(request.name, 'Cvetka Zupan');
      expect(request.email, 'cvetka@example.com');
      expect(request.tags, ['nova']);
      expect(repository.users, adapter.users);
    });

    test('updates only the selected user', () async {
      final originalSecondUser = adapter.users[1];
      final error = await adapter.updateUser(
        adapter.users.first.copyWith(name: 'Ana Kovač'),
      );

      expect(error, isNull);
      expect(adapter.users.first.name, 'Ana Kovač');
      expect(adapter.users[1], originalSecondUser);
      expect(repository.updatedUsers, hasLength(1));
      expect(repository.updatedUsers.single.id, 'user-1');
      expect(repository.updatedUsers.single.name, 'Ana Kovač');
      expect(repository.users, adapter.users);
    });

    test('deletes the selected user', () async {
      await adapter.deleteUser('user-1');

      expect(adapter.users.map((user) => user.id), ['user-2']);
      expect(repository.deletedUserIds, ['user-1']);
      expect(repository.users, adapter.users);
    });

    test(
      'filters users and restores the list when search is cleared',
      () async {
        await adapter.search('boris');
        expect(adapter.users.map((user) => user.id), ['user-2']);

        await adapter.search('');
        expect(adapter.users.map((user) => user.id), ['user-1', 'user-2']);
        expect(repository.filterQueries, ['boris']);
        expect(repository.getAllUsersCalls, [
          (page: 1, pageSize: 20),
          (page: 1, pageSize: 20),
        ]);
      },
    );

    test('returns a validation message and leaves state unchanged', () async {
      final before = List<User>.of(adapter.users);
      final error = await adapter.addUser(
        name: '',
        email: 'invalid',
        tags: const [],
      );

      expect(error, 'Name must be at least 2 characters.');
      expect(adapter.users, before);
      // This checks propagation of the fake's validation error, not the
      // production repository's validator (which is deliberately substituted).
      expect(repository.createdUsers, hasLength(1));
      expect(repository.users, before);
    });
  });

  group('dependency substitution and isolation', () {
    test(
      'uses an alternative injected repository for reads and writes',
      () async {
        final repository = FakeUserRepository(
          users: [
            testUser(
              id: 'alternative-user',
              name: 'Druga odvisnost',
              email: 'alternative@example.com',
            ),
          ],
        );
        final adapter = await start(repository);

        expect(adapter.users, repository.users);
        expect(adapter.users.single.id, 'alternative-user');
        expect(repository.getAllUsersCalls, [(page: 1, pageSize: 20)]);

        final updated = adapter.users.single.copyWith(
          name: 'Spremenjena odvisnost',
        );
        expect(await adapter.updateUser(updated), isNull);
        expect(repository.updatedUsers, [updated]);
        expect(adapter.users, repository.users);
      },
    );

    test(
      'awaits the injected asynchronous dependency without loading twice',
      () async {
        final gate = Completer<void>();
        final repository = FakeUserRepository(getUsersGate: gate.future);
        var initialized = false;
        final initialization = start(repository).then((adapter) {
          initialized = true;
          return adapter;
        });

        try {
          await repository.firstReadStarted.timeout(_initializationTimeout);
          // Let queued initialization continuations run while the dependency
          // remains blocked. No wall-clock delay or polling is needed.
          await Future<void>(() {});
          expect(initialized, isFalse);
          expect(repository.getAllUsersCalls, [(page: 1, pageSize: 20)]);
        } finally {
          // Never leave a pending constructor request, even when an assertion fails.
          gate.complete();
          await initialization;
        }

        final adapter = await initialization;
        expect(initialized, isTrue);
        expect(adapter.users, repository.users);
        expect(repository.getAllUsersCalls, [(page: 1, pageSize: 20)]);
      },
    );

    test(
      'does not reuse the previous dependency or state after cleanup',
      () async {
        final firstRepository = FakeUserRepository();
        final first = await start(firstRepository);
        await first.deleteUser('user-1');
        expect(first.users.map((user) => user.id), ['user-2']);
        await first.dispose();

        final secondRepository = FakeUserRepository();
        final second = await start(secondRepository);
        expect(second.users.map((user) => user.id), ['user-1', 'user-2']);
        expect(secondRepository.getAllUsersCalls, [(page: 1, pageSize: 20)]);
        expect(secondRepository.deletedUserIds, isEmpty);

        await second.deleteUser('user-2');
        expect(second.users.map((user) => user.id), ['user-1']);
        expect(secondRepository.deletedUserIds, ['user-2']);
        expect(firstRepository.deletedUserIds, ['user-1']);
        expect(firstRepository.users.map((user) => user.id), ['user-2']);
        expect(firstRepository.getAllUsersCalls, [(page: 1, pageSize: 20)]);
      },
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPageSize = BenchmarkConfig.instance.pageSize;
  final originalGetTestMode = Get.testMode;

  setUpAll(() {
    BenchmarkHarness.instance.setMeasurementsEnabled(false);
    BenchmarkConfig.instance.pageSize = 20;
  });

  tearDownAll(() {
    BenchmarkHarness.instance.setMeasurementsEnabled(true);
    BenchmarkConfig.instance.pageSize = originalPageSize;
    Get.testMode = originalGetTestMode;
  });

  group('Provider', () {
    runStateManagementContract(ProviderStateAdapter.new);
  });

  group('Riverpod', () {
    runStateManagementContract(RiverpodStateAdapter.new);
  });

  group('GetX', () {
    runStateManagementContract(GetXStateAdapter.new);
  });

  group('Watch_It', () {
    runStateManagementContract(WatchItStateAdapter.new);
  });
}
