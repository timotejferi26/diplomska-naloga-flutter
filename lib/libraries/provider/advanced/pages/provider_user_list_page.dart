// lib/libraries/provider/pages/provider_user_list_page.dart
//
// ADVANCED IMPLEMENTATION (fine-grained) variant.
// The page still watches the full notifier (loading/error/list), but each list
// item is wrapped in its own Provider<User>.value with value-equality
// updateShouldNotify, and the card is const. So when one user changes, only
// that item's scoped Provider notifies and only that const card rebuilds —
// the same mechanism as Riverpod's per-item ProviderScope.

import 'package:diplomska_naloga/core/services/benchmark/rebuild_tracker.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/notifiers/provider_user_notifier.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/widgets/provider_user_card.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/widgets/provider_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProviderUserListPage extends StatelessWidget {
  const ProviderUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);
    final notifier = context.watch<ProviderUserNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _SearchBar(
            onChanged: context.read<ProviderUserNotifier>().search,
          ),
        ),
      ),
      body: _buildBody(context, notifier),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => ProviderUserFormSheet(
            onSubmit: (name, email, tags) =>
                context.read<ProviderUserNotifier>().addUser(
                      name: name,
                      email: email,
                      tags: tags,
                    ),
          ),
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProviderUserNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.error != null) {
      return Center(child: Text('Error: ${notifier.error}'));
    }
    if (notifier.users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }
    return _UserList(
      users: notifier.users,
      hasMore: notifier.hasMore,
      isLoadingMore: notifier.isLoadingMore,
      onLoadMore: context.read<ProviderUserNotifier>().loadNextPage,
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
// StatefulWidget so we can own a ScrollController and listen for scroll-near-end
// to trigger onLoadMore. Implementation pattern is identical across all four
// libraries — only the listener/notifier wiring is different.

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

  // Distance from the bottom (in pixels) at which we trigger the next-page
  // load. 200 px is roughly half a card's height — far enough to feel
  // proactive, not so close that the user sees an empty bottom.
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
        return Provider<User>.value(
          key: ValueKey(widget.users[i].id),
          value: widget.users[i],
          updateShouldNotify: (previous, next) => previous != next,
          child: const ProviderUserCard(),
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
