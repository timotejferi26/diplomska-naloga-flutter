// lib/libraries/getx/widgets/getx_user_card.dart
//
// Each card finds its own user by id inside Obx().
// Only rebuilds when the users list changes AND this user's data changed.

import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show RebuildTracker;
import 'package:diplomska_naloga/libraries/getx/default/controllers/getx_user_controller.dart';
import 'package:diplomska_naloga/libraries/getx/default/widgets/getx_user_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GetXUserCard extends StatelessWidget {
  final String userId;
  const GetXUserCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    RebuildTracker.of(context)?.increment(context);
    final c = Get.find<GetXUserController>();

    return Obx(() {
      final user = c.users.firstWhereOrNull((u) => u.id == userId);
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
              // IconButton(
              //   icon: Icon(
              //     user.isFavorite ? Icons.favorite : Icons.favorite_border,
              //     color: user.isFavorite ? Colors.red : null,
              //   ),
              //   onPressed: () =>
              //       c.updateUser(user.copyWith(isFavorite: !user.isFavorite)),
              // ),
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
