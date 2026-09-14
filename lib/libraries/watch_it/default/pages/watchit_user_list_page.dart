// lib/libraries/watch_it/pages/watchit_user_list_page.dart
//
// Uses WatchItMixin — the idiomatic watch_it API.
// watchIt<T>() returns the ViewModel and subscribes to notifyListeners().
// No BuildContext needed to access the ViewModel — get_it handles it.

import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show RebuildTracker;
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/watch_it/default/view_models/watchit_user_view_model.dart';
import 'package:diplomska_naloga/libraries/watch_it/default/widgets/watchit_user_card.dart';
import 'package:diplomska_naloga/libraries/watch_it/default/widgets/watchit_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

class WatchItUserListPage extends WatchingWidget {
  const WatchItUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);

    // watchIt subscribes this widget to WatchItUserViewModel.notifyListeners()
    final vm = watchIt<WatchItUserViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('watch_it'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _SearchBar(onChanged: vm.search),
        ),
      ),
      body: _buildBody(context, vm),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => WatchItUserFormSheet(
            onSubmit: (name, email, tags) =>
                vm.addUser(name: name, email: email, tags: tags),
          ),
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WatchItUserViewModel vm) {
    if (vm.isLoading) return const Center(child: CircularProgressIndicator());
    if (vm.error != null) return Center(child: Text('Error: ${vm.error}'));
    if (vm.users.isEmpty) return const Center(child: Text('No users found.'));
    return _UserList(
      users: vm.users,
      hasMore: vm.hasMore,
      isLoadingMore: vm.isLoadingMore,
      onLoadMore: vm.loadNextPage,
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SearchBar(
        hintText: 'Search users...',
        leading: const Icon(Icons.search),
        onChanged: onChanged,
      ),
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────────

class _UserList extends StatefulWidget {
  final List<User> users;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const _UserList({
    required this.users,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  final _scrollController = ScrollController();
  static const _loadMoreThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFooter = widget.isLoadingMore || !widget.hasMore;
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.users.length + (hasFooter ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == widget.users.length) {
          return _ListFooter(
            isLoadingMore: widget.isLoadingMore,
            hasMore: widget.hasMore,
          );
        }
        return WatchItUserCard(
          key: ValueKey(widget.users[i].id),
          user: widget.users[i],
        );
      },
    );
  }
}

class _ListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  const _ListFooter({required this.isLoadingMore, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoadingMore
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (hasMore
                  ? const SizedBox.shrink()
                  : const Text(
                      '— konec seznama —',
                      style: TextStyle(color: Colors.grey),
                    )),
      ),
    );
  }
}
