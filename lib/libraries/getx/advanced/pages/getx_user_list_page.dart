// lib/libraries/getx/pages/getx_user_list_page.dart
//
// ADVANCED IMPLEMENTATION (fine-grained) variant.
// The body Obx observes ONLY `c.order` (the id sequence) plus loading/error —
// never the user values. So editing one user does not rebuild this Obx; only
// that user's own card Obx re-runs. The list is built from ids; each card looks
// up its own reactive user.

import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show RebuildTracker;
import 'package:diplomska_naloga/libraries/getx/advanced/controllers/getx_user_controller.dart';
import 'package:diplomska_naloga/libraries/getx/advanced/widgets/getx_user_card.dart';
import 'package:diplomska_naloga/libraries/getx/advanced/widgets/getx_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GetXUserListPage extends StatelessWidget {
  const GetXUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);
    final c = Get.find<GetXUserController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('GetX'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _SearchBar(onChanged: c.search),
        ),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.error.value != null) {
          return Center(child: Text('Error: ${c.error.value}'));
        }
        if (c.order.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        return _UserList(
          ids: c.order.toList(),
          hasMore: c.hasMore.value,
          isLoadingMore: c.isLoadingMore.value,
          onLoadMore: c.loadNextPage,
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => GetXUserFormSheet(
            onSubmit: (name, email, tags) =>
                c.addUser(name: name, email: email, tags: tags),
          ),
        ),
        child: const Icon(Icons.person_add),
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
        leading: const Icon(Icons.search),
        onChanged: onChanged,
      ),
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────────
//
// Driven by ids (the controller's `order`); each card resolves its own user.

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
        return GetXUserCard(
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
