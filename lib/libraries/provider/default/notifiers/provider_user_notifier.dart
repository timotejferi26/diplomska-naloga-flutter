// lib/libraries/provider/notifiers/provider_user_notifier.dart
//
// ChangeNotifier — calls notifyListeners() after every state change.
// context.select() in widgets ensures only affected widgets rebuild.
// Every action wrapped in BenchmarkHarness.measure().

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_config.dart';
import 'package:diplomska_naloga/core/services/benchmark/benchmark_harness.dart';
import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/exceptions/index.dart';
import 'package:diplomska_naloga/domain/usecases/index.dart';
import 'package:flutter/foundation.dart';

class ProviderUserNotifier extends ChangeNotifier {
  final UserUseCases _uc;
  static const _lib = 'provider';

  ProviderUserNotifier({required UserUseCases useCases}) : _uc = useCases {
    loadUsers();
  }

  // ── State ─────────────────────────────────────────────────────
  List<User> _users = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  bool _isSearching = false;
  String? _error;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore && !_isSearching;
  String? get error => _error;

  // ── Actions ───────────────────────────────────────────────────

  /// Initial load — resets pagination to page 1.
  Future<void> loadUsers({int page = 1}) async {
    _isLoading = true;
    _error = null;
    _isSearching = false;
    notifyListeners();
    try {
      await BenchmarkHarness.instance.measure(
        event: 'load_page_$page',
        library: _lib,
        action: () async {
          final result = await _uc.getUsers.call(PageParams(page: page, pageSize: BenchmarkConfig.instance.pageSize));
          _users = result;
          _page = page;
          _hasMore = result.length >= BenchmarkConfig.instance.pageSize;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load the next page and append it to the current list.
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _isSearching) return;
    _isLoadingMore = true;
    notifyListeners();
    final nextPage = _page + 1;
    try {
      await BenchmarkHarness.instance.measure(
        event: 'load_page_$nextPage',
        library: _lib,
        action: () async {
          final result = await _uc.getUsers.call(PageParams(page: nextPage, pageSize: BenchmarkConfig.instance.pageSize));
          _users = [..._users, ...result];
          _page = nextPage;
          _hasMore = result.length >= BenchmarkConfig.instance.pageSize;
          _isLoadingMore = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<String?> addUser({
    required String name,
    required String email,
    required List<String> tags,
  }) async {
    try {
      return await BenchmarkHarness.instance.measure(
        event: 'add_user',
        library: _lib,
        action: () async {
          final created = await _uc.addUser.call(
            AddUserParams(name: name, email: email, tags: tags),
          );
          _users = [created, ..._users];
          notifyListeners();
          return null;
        },
      );
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
          _users = _users.map((u) => u.id == updated.id ? updated : u).toList();
          notifyListeners();
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
        _users = _users.where((u) => u.id != id).toList();
        notifyListeners();
      },
    );
  }

  Future<void> search(String query) async {
    _isLoading = true;
    notifyListeners();
    try {
      await BenchmarkHarness.instance.measure(
        event: query.isEmpty ? 'search_clear' : 'search_query',
        library: _lib,
        action: () async {
          if (query.isEmpty) {
            // Clearing search → return to paginated mode at page 1.
            _isSearching = false;
            final result = await _uc.getUsers.call(PageParams(page: 1, pageSize: BenchmarkConfig.instance.pageSize));
            _users = result;
            _page = 1;
            _hasMore = result.length >= BenchmarkConfig.instance.pageSize;
          } else {
            // Search mode — pagination is paused, all matches returned.
            _isSearching = true;
            _users = await _uc.searchUsers.call(SearchParams(query));
          }
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
