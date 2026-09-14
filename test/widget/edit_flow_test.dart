import 'package:diplomska_naloga/libraries/watch_it/advanced/view_models/watchit_user_view_model.dart';
import 'package:diplomska_naloga/main_advanced.dart' as advanced_app;
import 'package:diplomska_naloga/main_default.dart' as default_app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:watch_it/watch_it.dart';

typedef BeforeEdit = Future<void> Function(WidgetTester tester);

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 120,
}) async {
  for (var i = 0; i < attempts; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Widget was not found: $finder');
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  int attempts = 120,
}) async {
  for (var i = 0; i < attempts; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Widget was still present: $finder');
}

Future<void> _verifyEdit(
  WidgetTester tester, {
  required Widget app,
  required String library,
  required String updatedName,
  BeforeEdit? beforeEdit,
}) async {
  await tester.pumpWidget(app);
  await tester.tap(find.text(library));
  await _pumpUntil(tester, find.byIcon(Icons.edit_outlined));

  if (beforeEdit != null) {
    await beforeEdit(tester);
    await tester.pump(const Duration(milliseconds: 200));
  }

  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await _pumpUntil(tester, find.text('Save Changes'));
  await tester.enterText(find.byKey(const Key('field_name')), updatedName);
  await tester.ensureVisible(find.text('Save Changes'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save Changes'));
  await _pumpUntilGone(tester, find.text('Save Changes'));

  final updatedCard = find.descendant(
    of: find.byType(ListTile),
    matching: find.text(updatedName),
  );
  await _pumpUntil(tester, updatedCard);
  expect(updatedCard, findsOneWidget);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 250));
  Get.reset();
}

void main() {
  const libraries = ['Provider', 'Riverpod', 'GetX', 'Watch_It'];

  for (final library in libraries) {
    testWidgets('$library default card displays an edited user', (
      tester,
    ) async {
      await _verifyEdit(
        tester,
        app: const default_app.MyApp(),
        library: library,
        updatedName: 'Default $library user',
      );
    });

    testWidgets('$library advanced card displays an edited user', (
      tester,
    ) async {
      await _verifyEdit(
        tester,
        app: const advanced_app.MyApp(),
        library: library,
        updatedName: 'Advanced $library user',
        // Re-loading replaces Watch_It's per-item ValueNotifier instances.
        // The mounted card must switch its subscription to the replacement.
        beforeEdit: library == 'Watch_It'
            ? (tester) async {
                final vm = di<WatchItUserViewModel>();
                final load = vm.loadUsers();
                while (vm.isLoading.value) {
                  await tester.pump(const Duration(milliseconds: 50));
                }
                await tester.pump(const Duration(milliseconds: 200));
                await load;
              }
            : null,
      );
    });
  }
}
