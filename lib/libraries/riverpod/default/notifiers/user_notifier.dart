// lib/libraries/riverpod/notifiers/user_notifier.dart
//
// AsyncNotifier<List<User>> — Riverpod 2.x modern pattern.
// build() is called once on mount and returns the initial data load.
// Every action is wrapped in BenchmarkHarness.measure() for instrumentation.

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_config.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_harness.dart';
import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/exceptions/not_found_exception.dart';
import 'package:diplomska_naloga/domain/exceptions/validation_exception.dart';
import 'package:diplomska_naloga/domain/usecases/add_user_usecase.dart';
import 'package:diplomska_naloga/libraries/riverpod/default/di/riverpod_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserNotifier extends AsyncNotifier<List<User>> {
  static const _lib = 'riverpod';

  UserUseCases get _uc => ref.read(useCasesProvider);

  // ── Pagination state ─────────────────────────────────────────
  // Kept as plain instance fields so the field access pattern is identical
  // across the four library implementations. Riverpod's reactive state
  // (`state` of type AsyncValue<List<User>>) holds only the user list.
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;

  bool get hasMore => _hasMore && !_isSearching;
  bool get isLoadingMore => _isLoadingMore;

  // build() = initial load — Riverpod calls this automatically on first watch.
  // We set state manually inside the action so that rebuilds triggered by
  // the state change fall within the measurement window. Riverpod then
  // reconciles the same value when build() returns, which is a no-op.
  @override
  Future<List<User>> build() async {
    return BenchmarkHarness.instance.measure(
      event: 'load_page_1',
      library: _lib,
      action: () async {
        final result = await _uc.getUsers.call(PageParams(page: 1, pageSize: BenchmarkConfig.instance.pageSize));
        _page = 1;
        _isSearching = false;
        _hasMore = result.length >= BenchmarkConfig.instance.pageSize;
        state = AsyncData(result);
        return result;
      },
    );
  }

  // ── Actions ───────────────────────────────────────────────────

  Future<void> loadPage(int page) async {
    state = const AsyncLoading();
    await BenchmarkHarness.instance.measure(
      event: 'load_page_$page',
      library: _lib,
      action: () async {
        state = await AsyncValue.guard(() async {
          final result = await _uc.getUsers.call(PageParams(page: page, pageSize: BenchmarkConfig.instance.pageSize));
          _page = page;
          _isSearching = false;
          _hasMore = result.length >= BenchmarkConfig.instance.pageSize;
          return result;
        });
      },
    );
  }

  /// Append the next page to the existing list.
  ///
  /// Note: `_isLoadingMore` is set during the operation but listeners only
  /// receive a single notification — when `state = AsyncData(...)` fires at
  /// the end. The intermediate "true" flag is therefore not observable to
  /// the UI. For benchmark purposes this is acceptable; for a production
  /// app, the pagination metadata would be in its own `StateProvider`.
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _isSearching) return;
    final current = state.value;
    if (current == null) return;
    _isLoadingMore = true;
    final nextPage = _page + 1;
    try {
      await BenchmarkHarness.instance.measure(
        event: 'load_page_$nextPage',
        library: _lib,
        action: () async {
          final result = await _uc.getUsers.call(PageParams(page: nextPage, pageSize: BenchmarkConfig.instance.pageSize));
          _page = nextPage;
          _hasMore = result.length >= BenchmarkConfig.instance.pageSize;
          _isLoadingMore = false;
          state = AsyncData([...current, ...result]);
        },
      );
    } catch (_) {
      _isLoadingMore = false;
      state = AsyncError(StateError('Load page failed'), StackTrace.current);
    }
  }

  Future<String?> addUser({
    required String name,
    required String email,
    required List<String> tags,
  }) async {
    try {
      await BenchmarkHarness.instance.measure(
        event: 'add_user',
        library: _lib,
        action: () async {
          final created = await _uc.addUser.call(
            AddUserParams(name: name, email: email, tags: tags),
          );
          state.whenData((users) {
            state = AsyncData([created, ...users]);
          });
        },
      );
      return null; // null = success
    } on ValidationException catch (e) {
      return e.message; // return message to show in form
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> updateUser(User user) async {
    try {
      await BenchmarkHarness.instance.measure(
        event: 'edit_user',
        library: _lib,
        action: () async {
          final updated = await _uc.updateUser.call(user);
          state.whenData((users) {
            state = AsyncData(
              users.map((u) => u.id == updated.id ? updated : u).toList(),
            );
          });
        },
      );
      return null;
    } on ValidationException catch (e) {
      return e.message;
    } on NotFoundException {
      return 'User no longer exists.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> deleteUser(String id) async {
    await BenchmarkHarness.instance.measure(
      event: 'delete_user',
      library: _lib,
      action: () async {
        await _uc.deleteUser.call(id);
        state.whenData((users) {
          state = AsyncData(users.where((u) => u.id != id).toList());
        });
      },
    );
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    await BenchmarkHarness.instance.measure(
      event: query.isEmpty ? 'search_clear' : 'search_query',
      library: _lib,
      action: () async {
        state = await AsyncValue.guard(() async {
          if (query.isEmpty) {
            // Clearing search → return to paginated mode at page 1.
            _isSearching = false;
            final result = await _uc.getUsers.call(PageParams(page: 1, pageSize: BenchmarkConfig.instance.pageSize));
            _page = 1;
            _hasMore = result.length >= BenchmarkConfig.instance.pageSize;
            return result;
          } else {
            _isSearching = true;
            return await _uc.searchUsers.call(SearchParams(query));
          }
        });
      },
    );
  }
}
