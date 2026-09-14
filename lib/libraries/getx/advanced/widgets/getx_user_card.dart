// lib/libraries/getx/widgets/getx_user_card.dart
//
// ADVANCED IMPLEMENTATION (fine-grained) variant.
// The Obx observes ONLY this user's own Rx<User> (controller.userById), so it
// re-runs only when THIS user changes — not when any user in the list changes.
// Because the list page observes only `order`, a single edit does not
// cascade-rebuild the card; the rebuild happens inside the Obx.
//
// The rebuild counter therefore sits INSIDE the Obx: for GetX the Obx closure —
// not the widget's build() — is the reactive rebuild unit. (The other three
// libraries subscribe at the widget level, so their counter sits at build().)
// The InheritedWidget lookup (RebuildTracker.of) stays in build(); only the
// increment, which just reads element info, runs inside the Obx.

import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show RebuildTracker;
import 'package:diplomska_naloga/libraries/getx/advanced/controllers/getx_user_controller.dart';
import 'package:diplomska_naloga/libraries/getx/advanced/widgets/getx_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GetXUserCard extends StatelessWidget {
  final String userId;
  const GetXUserCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<GetXUserController>();
    final tracker = RebuildTracker.of(context);

    return Obx(() {
      tracker?.increment(context);
      final rx = c.userById(userId);
      if (rx == null) return const SizedBox.shrink();
      final user = rx.value;

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
                  builder: (_) => GetXUserFormSheet(
                    existing: user,
                    onSubmit: (name, email, tags) => c.updateUser(
                      user.copyWith(name: name, email: email, tags: tags),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => c.deleteUser(user.id),
              ),
            ],
          ),
        ),
      );
    });
  }
}
