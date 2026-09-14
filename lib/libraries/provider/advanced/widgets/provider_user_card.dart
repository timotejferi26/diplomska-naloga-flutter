// lib/libraries/provider/widgets/provider_user_card.dart
//
// ADVANCED IMPLEMENTATION (fine-grained) variant.
// The card is declared const and reads its User from a per-item
// Provider<User>.value injected by the list page. This mirrors Riverpod's
// per-item ProviderScope: the const card is not rebuilt by the parent's
// cascade, and the scoped Provider<User> only notifies when THIS user's value
// actually changes (value-equality), so editing one user rebuilds one card.

import 'package:diplomska_naloga/core/services/benchmark/rebuild_tracker.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/notifiers/provider_user_notifier.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/widgets/provider_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show ReadContext, WatchContext;

class ProviderUserCard extends StatelessWidget {
  const ProviderUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);

    // Per-item scoped value — supplied by Provider<User>.value in the list.
    final user = context.watch<User>();

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
                  context.read<ProviderUserNotifier>().deleteUser(user.id),
            ),
          ],
        ),
      ),
    );
  }
}
