// lib/libraries/riverpod/pages/riverpod_user_list_page.dart
//
// List page — watches userNotifierProvider for the full user list.
// Each card gets its own ProviderScope so it only rebuilds when its
// specific user changes, not when any user in the list changes.

import 'package:diplomska_naloga/core/services/benchmark/rebuild_tracker.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/riverpod/default/di/riverpod_providers.dart';
import 'package:diplomska_naloga/libraries/riverpod/default/widgets/riverpod_user_card.dart';
import 'package:diplomska_naloga/libraries/riverpod/default/widgets/riverpod_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiverpodUserListPage extends ConsumerWidget {
  const RiverpodUserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    RebuildTracker.of(context)?.increment(context);

    final state = ref.watch(userNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _SearchBar(
            onChanged: (q) => ref.read(userNotifierProvider.notifier).search(q),
          ),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          final notifier = ref.read(userNotifierProvider.notifier);
          return _UserList(
            users: users,
            hasMore: notifier.hasMore,
            isLoadingMore: notifier.isLoadingMore,
            onLoadMore: notifier.loadNextPage,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RiverpodUserFormSheet(
        onSubmit: (name, email, tags) => ref
            .read(userNotifierProvider.notifier)
            .addUser(name: name, email: email, tags: tags),
      ),
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
        onChanged: onChanged,
        leading: const Icon(Icons.search),
      ),
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────────
//
// StatefulWidget so we can own a ScrollController and listen for scroll-near-end
// to trigger onLoadMore. Pattern matches the other three library implementations.

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
    if (widget.users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }
    final hasFooter = widget.isLoadingMore || !widget.hasMore;
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.users.length + (hasFooter ? 1 : 0),
      itemBuilder: (_, index) {
        if (index == widget.users.length) {
          return _ListFooter(
            isLoadingMore: widget.isLoadingMore,
            hasMore: widget.hasMore,
          );
        }
        final user = widget.users[index];
        return ProviderScope(
          key: ValueKey(user.id),
          overrides: [userItemProvider.overrideWithValue(user)],
          child: const RiverpodUserCard(),
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
