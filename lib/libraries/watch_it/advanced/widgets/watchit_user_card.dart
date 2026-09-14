// lib/libraries/watch_it/widgets/watchit_user_card.dart
//
// ADVANCED IMPLEMENTATION (fine-grained) variant.
// The card watchValue()s ONLY its own user's ValueListenable (vm.listenableFor),
// so its build() re-runs only when THIS user changes — not when any user in the
// list changes. The list page watches only `order`, so a single edit does not
// cascade-rebuild the card. For watch_it the reactive subscription is at the
// widget level (WatchingWidget), so the rebuild counter stays at the top of
// build(). Actions use di<VM>() (a non-reactive read).

import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show RebuildTracker;
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/libraries/watch_it/advanced/view_models/watchit_user_view_model.dart';
import 'package:diplomska_naloga/libraries/watch_it/advanced/widgets/watchit_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

class WatchItUserCard extends WatchingWidget {
  final String userId;
  const WatchItUserCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);

    // Watches ONLY this user's listenable — fine-grained per-item subscription.
    final User user = watchValue(
      (WatchItUserViewModel x) => x.listenableFor(userId),
      // Loading and searching can replace the per-item ValueNotifier while
      // preserving this card's key. Re-evaluate the selector so the mounted
      // card switches its subscription to the current notifier.
      allowObservableChange: true,
    );
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
