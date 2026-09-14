// lib/libraries/watch_it/widgets/watchit_user_card.dart
//
// Passive display card — mirrors the official watch_it weather demo, where
// list items are plain widgets fed by a single watch at the list level
// (WatchItUserListPage does watchIt<VM>() once). The card receives its User
// by constructor and does NOT watch the VM itself; di<T>() is a non-reactive
// read of the service locator used only to invoke actions.

import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/watch_it/default/view_models/watchit_user_view_model.dart';
import 'package:diplomska_naloga/libraries/watch_it/default/widgets/watchit_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart' show di;

import '../../../../core/services/benchmark/index.dart' show RebuildTracker;

class WatchItUserCard extends StatelessWidget {
  final User user;
  const WatchItUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);

    // Non-reactive read — the card does not subscribe; the list page's
    // watchIt<VM>() drives rebuilds. di<T>() is only used to call actions.
    final vm = di<WatchItUserViewModel>();

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
                builder: (_) => WatchItUserFormSheet(
                  existing: user,
                  onSubmit: (name, email, tags) => vm.updateUser(
                    user.copyWith(name: name, email: email, tags: tags),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => vm.deleteUser(user.id),
            ),
          ],
        ),
      ),
    );
  }
}
