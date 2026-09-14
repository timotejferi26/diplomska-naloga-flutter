// lib/libraries/watch_it/view_models/watchit_user_view_model.dart
//
// ADVANCED IMPLEMENTATION (fine-grained) variant.
// State is exposed as per-item ValueNotifier<User> (keyed by id) plus a
// ValueNotifier<List<String>> `order` for the visible sequence and small
// ValueNotifiers for loading/error. The list page watchValue()s only `order`
// (+ loading/error); each card watchValue()s ONLY its own user's listenable.
// So editing one user notifies a single ValueNotifier — the page does not
// rebuild and only that card re-runs.

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_config.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_harness.dart';
import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/exceptions/index.dart';
import 'package:diplomska_naloga/domain/usecases/index.dart';
import 'package:flutter/foundation.dart';

class WatchItUserViewModel {
  final UserUseCases _uc;
  static const _lib = 'watch_it';

  WatchItUserViewModel({required UserUseCases useCases}) : _uc = useCases {
    loadUsers();
  }

  // ── State (each piece independently observable) ───────────────
  final Map<String, ValueNotifier<User>> _byId = {};
  final ValueNotifier<List<String>> order = ValueNotifier(<String>[]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> isLoadingMore = ValueNotifier(false);
  final ValueNotifier<bool> hasMore = ValueNotifier(true);
  final ValueNotifier<String?> error = ValueNotifier(null);

  int _page = 1;
  bool _isSearching = false;

  /// The listenable for one user — watched by its own card so that only that
  /// card rebuilds when this user changes.
  ValueListenable<User> listenableFor(String id) => _byId[id]!;

  // ── Helpers ───────────────────────────────────────────────────

  void _setAll(List<User> list) {
    _byId.clear();
    for (final u in list) {
      _byId[u.id] = ValueNotifier(u);
    }
    order.value = list.map((u) => u.id).toList();
  }

  void _appendAll(List<User> list) {
    for (final u in list) {
      _byId[u.id] = ValueNotifier(u);
    }
    order.value = [...order.value, ...list.map((u) => u.id)];
  }

  // ── Actions ───────────────────────────────────────────────────

  Future<void> loadUsers({int page = 1}) async {
    isLoading.value = true;
    error.value = null;
    _isSearching = false;
    try {
      await BenchmarkHarness.instance.measure(
        event: 'load_page_$page',
        library: _lib,
        action: () async {
          final result = await _uc.getUsers.call(PageParams(page: page, pageSize: BenchmarkConfig.instance.pageSize));
          _setAll(result);
          _page = page;
          hasMore.value = result.length >= BenchmarkConfig.instance.pageSize;
          isLoading.value = false;
        },
      );
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoadingMore.value || !hasMore.value || _isSearching) return;
    isLoadingMore.value = true;
    final nextPage = _page + 1;
    try {
      await BenchmarkHarness.instance.measure(
        event: 'load_page_$nextPage',
        library: _lib,
        action: () async {
          final result = await _uc.getUsers.call(PageParams(page: nextPage, pageSize: BenchmarkConfig.instance.pageSize));
          _appendAll(result);
          _page = nextPage;
          hasMore.value = result.length >= BenchmarkConfig.instance.pageSize;
          isLoadingMore.value = false;
        },
      );
    } catch (e) {
      error.value = e.toString();
      isLoadingMore.value = false;
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
          _byId[created.id] = ValueNotifier(created);
          order.value = [created.id, ...order.value];
        },
      );
      return null;
    } on ValidationException catch (e) {
      return e.message;
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
          // Notify only this user's listenable — `order` untouched, so the page
          // does not rebuild and only this card re-runs.
          _byId[updated.id]?.value = updated;
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
        _byId.remove(id);
        order.value = order.value.where((e) => e != id).toList();
      },
    );
  }

  Future<void> search(String query) async {
    isLoading.value = true;
    try {
      await BenchmarkHarness.instance.measure(
        event: query.isEmpty ? 'search_clear' : 'search_query',
        library: _lib,
        action: () async {
          if (query.isEmpty) {
            // Clearing search → return to paginated mode at page 1.
            _isSearching = false;
            final result = await _uc.getUsers.call(PageParams(page: 1, pageSize: BenchmarkConfig.instance.pageSize));
            _setAll(result);
            _page = 1;
            hasMore.value = result.length >= BenchmarkConfig.instance.pageSize;
          } else {
            _isSearching = true;
            final result = await _uc.searchUsers.call(SearchParams(query));
            _setAll(result);
          }
          isLoading.value = false;
        },
      );
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
    }
  }
}
