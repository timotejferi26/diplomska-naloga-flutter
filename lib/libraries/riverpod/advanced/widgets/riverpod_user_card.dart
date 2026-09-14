// lib/libraries/riverpod/widgets/riverpod_user_card.dart
//
// Watches userItemProvider — scoped per-item via ProviderScope in the list.
// Only rebuilds when THIS user's data changes, not the whole list.
// Uses .select() for the favorite icon so only the icon rebuilds on toggle.

import 'package:diplomska_naloga/core/services/benchmark/rebuild_tracker.dart';
import 'package:diplomska_naloga/libraries/riverpod/advanced/di/riverpod_providers.dart';
import 'package:diplomska_naloga/libraries/riverpod/advanced/widgets/riverpod_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiverpodUserCard extends ConsumerWidget {
  const RiverpodUserCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    RebuildTracker.of(context)?.increment(context);

    final user = ref.watch(userItemProvider);
    // final isFavorite = ref.watch(userItemProvider.select((u) => u.isFavorite));
    final notifier = ref.read(userNotifierProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email),
        leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favorite — only this icon rebuilds on toggle
            // IconButton(
            //   icon: Icon(
            //     isFavorite ? Icons.favorite : Icons.favorite_border,
            //     color: isFavorite ? Colors.red : null,
            //   ),
            //   onPressed: () =>
            //       notifier.updateUser(user.copyWith(isFavorite: !isFavorite)),
            // ),
            // Edit
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => RiverpodUserFormSheet(
                  existing: user,
                  onSubmit: (name, email, tags) => notifier.updateUser(
                    user.copyWith(name: name, email: email, tags: tags),
                  ),
                ),
              ),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => notifier.deleteUser(user.id),
            ),
          ],
        ),
      ),
    );
  }
}
