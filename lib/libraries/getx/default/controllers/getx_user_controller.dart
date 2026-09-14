// lib/libraries/getx/controllers/getx_user_controller.dart
//
// GetxController — reactive state via .obs variables.
// Every action is wrapped in BenchmarkHarness.measure().

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show BenchmarkConfig, BenchmarkHarness;
import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/exceptions/index.dart';
import 'package:diplomska_naloga/domain/usecases/index.dart' show AddUserParams;
import 'package:get/get.dart';

class GetXUserController extends GetxController {
  final UserUseCases _uc;
  static const _lib = 'getx';

  GetXUserController({required UserUseCases useCases}) : _uc = useCases;

  // ── Observable state ──────────────────────────────────────────
  final users = <User>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final error = RxnString();

  // ── Internal pagination state ────────────────────────────────
  int _page = 1;
  bool _isSearching = false;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
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
          users.value = result;
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

  /// Load the next page and append.
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
          users.value = [...users, ...result];
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

  /// Returns null on success, error message on failure.
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
          users.insert(0, created);
        },
      );
      return null;
    } on ValidationException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> updateUser(User user) async {
    try {
      await BenchmarkHarness.instance.measure(
        event: 'edit_user',
        library: _lib,
        action: () async {
          final updated = await _uc.updateUser.call(user);
          final idx = users.indexWhere((u) => u.id == updated.id);
          if (idx != -1) users[idx] = updated;
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
    try {
      await BenchmarkHarness.instance.measure(
        event: 'delete_user',
        library: _lib,
        action: () async {
          await _uc.deleteUser.call(id);
          // Reassign rather than mutate — after a search_clear, `users.value`
          // can be an unmodifiable list returned from the fake datasource,
          // and calling removeWhere on it would throw silently.
          users.value = users.where((u) => u.id != id).toList();
        },
      );
    } catch (e) {
      error.value = e.toString();
    }
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
            users.value = result;
            _page = 1;
            hasMore.value =
                result.length >= BenchmarkConfig.instance.pageSize;
          } else {
            _isSearching = true;
            final result = await _uc.searchUsers.call(SearchParams(query));
            users.value = result;
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
