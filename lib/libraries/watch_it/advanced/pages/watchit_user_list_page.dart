// lib/libraries/watch_it/pages/watchit_user_list_page.dart
//
// ADVANCED IMPLEMENTATION (fine-grained) variant.
// The page watchValue()s only structural state — `order` (id sequence),
// loading/error and the pagination flags — never the user values. So editing
// one user does not rebuild this page; only that user's own card re-runs. The
// list is built from ids; each card watches its own reactive user.

import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show RebuildTracker;
import 'package:diplomska_naloga/libraries/watch_it/advanced/view_models/watchit_user_view_model.dart';
import 'package:diplomska_naloga/libraries/watch_it/advanced/widgets/watchit_user_card.dart';
import 'package:diplomska_naloga/libraries/watch_it/advanced/widgets/watchit_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

class WatchItUserListPage extends WatchingWidget {
  const WatchItUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);

    final vm = di<WatchItUserViewModel>();
    final isLoading = watchValue((WatchItUserViewModel x) => x.isLoading);
    final error = watchValue((WatchItUserViewModel x) => x.error);
    final ids = watchValue((WatchItUserViewModel x) => x.order);
    final hasMore = watchValue((WatchItUserViewModel x) => x.hasMore);
    final isLoadingMore = watchValue((WatchItUserViewModel x) => x.isLoadingMore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('watch_it'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _SearchBar(onChanged: vm.search),
        ),
      ),
      body: _buildBody(
        isLoading: isLoading,
        error: error,
        ids: ids,
        hasMore: hasMore,
        isLoadingMore: isLoadingMore,
        onLoadMore: vm.loadNextPage,
      ),
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

  Widget _buildBody({
    required bool isLoading,
    required String? error,
    required List<String> ids,
    required bool hasMore,
    required bool isLoadingMore,
    required VoidCallback onLoadMore,
  }) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));
    if (ids.isEmpty) return const Center(child: Text('No users found.'));
    return _UserList(
      ids: ids,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
      onLoadMore: onLoadMore,
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
//
// Driven by ids (the VM's `order`); each card watches its own user.

class _UserList extends StatefulWidget {
  final List<String> ids;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const _UserList({
    required this.ids,
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
      itemCount: widget.ids.length + (hasFooter ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == widget.ids.length) {
          return _ListFooter(
            isLoadingMore: widget.isLoadingMore,
            hasMore: widget.hasMore,
          );
        }
        return WatchItUserCard(
          key: ValueKey(widget.ids[i]),
          userId: widget.ids[i],
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
