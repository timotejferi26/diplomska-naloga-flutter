// lib/libraries/provider/widgets/provider_user_card.dart
//
// Uses context.select() to watch only THIS user — not the whole list.
// The favorite IconButton is extracted to its own widget so only
// the icon rebuilds when isFavorite toggles.

import 'package:diplomska_naloga/core/services/benchmark/rebuild_tracker.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/provider/default/notifiers/provider_user_notifier.dart';
import 'package:diplomska_naloga/libraries/provider/default/widgets/provider_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show ReadContext, SelectContext;

class ProviderUserCard extends StatelessWidget {
  final String userId;
  const ProviderUserCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);

    // Only rebuilds when THIS user's data changes
    final user = context.select<ProviderUserNotifier, User?>(
      (n) => n.users.where((u) => u.id == userId).firstOrNull,
    );

    if (user == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // _FavoriteButton(userId: userId),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => ProviderUserFormSheet(
                  existing: user,
                  onSubmit: (name, email, tags) =>
                      context.read<ProviderUserNotifier>().updateUser(
                            user.copyWith(
                              name: name,
                              email: email,
                              tags: tags,
                            ),
                          ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () =>
                  context.read<ProviderUserNotifier>().deleteUser(userId),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracted widget — only rebuilds when isFavorite changes for this user.
// class _FavoriteButton extends StatelessWidget {
//   final String userId;
//   const _FavoriteButton({required this.userId});

//   @override
//   Widget build(BuildContext context) {
//     // final isFavorite = context.select<ProviderUserNotifier, bool>(
//     //   (n) => n.users.where((u) => u.id == userId).firstOrNull?.isFavorite ?? false,
//     // );
//     final notifier = context.read<ProviderUserNotifier>();
//     final user = notifier.users.where((u) => u.id == userId).firstOrNull;

//     return IconButton(
//       icon: Icon(
//         isFavorite ? Icons.favorite : Icons.favorite_border,
//         color: isFavorite ? Colors.red : null,
//       ),
//       onPressed: user == null
//           ? null
//           : () => notifier.updateUser(user.copyWith(isFavorite: !isFavorite)),
//     );
//   }
// }
