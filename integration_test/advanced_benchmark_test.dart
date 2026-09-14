// integration_test/advanced_benchmark_test.dart
//
// HOW TO RUN:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/advanced_benchmark_test.dart \
//     --profile

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:diplomska_naloga/main_advanced.dart' as app;
import 'package:diplomska_naloga/core/services/benchmark/index.dart'
    show
        BenchmarkConfig,
        BenchmarkHarness,
        BenchmarkPreset,
        BenchmarkResult,
        FrameworkRebuildTracker,
        MetricsExporter;

const _kNameField = Key('field_name');
const _kEmailField = Key('field_email');
const _kTagsField = Key('field_tags');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // ── Pump ───────────────────────────────────────────────────────────────────

  Future<void> pump(WidgetTester tester, {int maxMs = 5000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: maxMs));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      try {
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
        return;
      } catch (_) {}
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    int maxSeconds = 15,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: maxSeconds));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('waitFor timed out (${maxSeconds}s): $finder');
  }

  // ── Keyboard ───────────────────────────────────────────────────────────────

  Future<void> hideKeyboard(WidgetTester tester) async {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    try {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    } catch (_) {}
    await tester.pump(const Duration(milliseconds: 800));
    await pump(tester, maxMs: 2000);
  }

  // ── Tap via raw coordinate — bypasses Android IME overlay hit-test ─────────

  Future<void> rawTap(WidgetTester tester, Finder finder) async {
    final element = finder.evaluate().first;
    final renderBox = element.renderObject as RenderBox;
    final center = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    await tester.tapAt(center);
    await pump(tester);
  }

  // ── Text input — sets controller value directly via EditableText ───────────
  //
  // On real Android, enterText / showKeyboard are unreliable because the
  // platform IME and Flutter's test input channel compete.
  //
  // Strategy:
  //   1. rawTap the field to give it focus
  //   2. pump to let focus settle
  //   3. Use testTextInput.updateEditingValue to inject text directly
  //      into Flutter's text input system — this never touches the IME
  //   4. Also set the controller text directly as a fallback, because
  //      updateEditingValue only works when the field holds the connection

  Future<void> fillField(WidgetTester tester, Key fieldKey, String text) async {
    final finder = find.byKey(fieldKey);
    await waitFor(tester, finder);
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 200));

    // 1. Tap to focus
    await rawTap(tester, finder);
    await tester.pump(const Duration(milliseconds: 400));

    // 2. Inject via the low-level text input channel
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // 3. Also write directly into the controller as a belt-and-suspenders
    //    fallback — finds the EditableText under the keyed TextFormField
    //    and updates its controller
    final editableTextFinder = find.descendant(
      of: finder,
      matching: find.byType(EditableText),
    );
    if (editableTextFinder.evaluate().isNotEmpty) {
      final editableText = tester.widget<EditableText>(editableTextFinder);
      editableText.controller.text = text;
      editableText.controller.selection = TextSelection.collapsed(
        offset: text.length,
      );
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  // ── Search bar input ───────────────────────────────────────────────────────
  //
  // Material's SearchBar wraps an internal TextField with its own controller.
  // updateEditingValue is unreliable on real Android (IME vs test channel)
  // and setting controller.text does NOT trigger SearchBar.onChanged because
  // TextField only fires onChanged on user-driven input, not controller writes.
  //
  // Strategy: grab the SearchBar widget instance and invoke its onChanged
  // callback directly. This is what user input would have triggered — same
  // code path through the app's search logic, just skipping the IME layer.

  Future<void> fillSearchBar(WidgetTester tester, String text) async {
    final searchBarFinder = find.byType(SearchBar);
    await waitFor(tester, searchBarFinder);
    await tester.ensureVisible(searchBarFinder.first);
    await tester.pump(const Duration(milliseconds: 200));

    final searchBar = tester.widget<SearchBar>(searchBarFinder.first);
    searchBar.onChanged?.call(text);
    await tester.pump(const Duration(milliseconds: 200));
  }

  // ── Add user form ──────────────────────────────────────────────────────────

  Future<void> addUser(
    WidgetTester tester, {
    required String name,
    required String email,
    String tags = 'flutter, benchmark',
  }) async {
    await hideKeyboard(tester);

    // Open bottom sheet
    final fab = find.byIcon(Icons.person_add);
    await waitFor(tester, fab);
    await rawTap(tester, fab);
    await waitFor(tester, find.byKey(_kNameField));

    // Fill all three fields
    await fillField(tester, _kNameField, name);
    await fillField(tester, _kEmailField, email);
    await fillField(tester, _kTagsField, tags);

    await hideKeyboard(tester);

    // Submit
    final submitBtn = find.widgetWithText(FilledButton, 'Add User');
    await waitFor(tester, submitBtn);
    await rawTap(tester, submitBtn);
    await pump(tester);
  }

  // ── Scroll trigger for pagination ──────────────────────────────────────────
  //
  // Deterministic + adaptive pagination trigger. Earlier versions used
  // tester.fling() at high velocity (6000 px/s); its inertia cascaded through
  // several page loads and churned many cards through the viewport, so the
  // load_page_* rebuild counts varied run-to-run.
  //
  // Instead we read the list's ACTUAL maxScrollExtent (which scales with the
  // preset's page size, so heavy reaches the new page too) and jumpTo() the
  // bottom. jumpTo carries no momentum, so it fires the _UserListState
  // listener — and thus loadNextPage() — exactly once: no inertial cascade,
  // and ListView.builder only renders the destination viewport (no churn
  // through intermediate cards). The notifier's isLoadingMore guard prevents
  // re-entry; the list grows only after the jump, so the position stays at the
  // old bottom and does not re-trigger. Called twice → load_page_2 + load_page_3.

  Future<void> scrollToLoadMore(WidgetTester tester) async {
    final listFinder = find.byType(ListView);
    if (listFinder.evaluate().isEmpty) return;
    final scrollable = find.descendant(
      of: listFinder.first,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable.first).position;
    if (position.maxScrollExtent - position.pixels <= 0) return;

    position.jumpTo(position.maxScrollExtent);
    await pump(tester);
    // Allow the async page load to resolve and state to update.
    await tester.pump(const Duration(milliseconds: 500));
    await pump(tester);
  }

  // ── Core sequence ──────────────────────────────────────────────────────────

  Future<void> runLibrarySequence(WidgetTester tester, String menuText) async {
    // 1. Navigate
    await waitFor(tester, find.text(menuText));
    await rawTap(tester, find.text(menuText));
    await tester.pump(const Duration(seconds: 3));

    // 2. Add 5 users
    for (int i = 1; i <= 5; i++) {
      await addUser(
        tester,
        name: 'Test User $i',
        email: 'user$i@benchmark.dev',
      );
    }

    // 3. Edit first user
    await hideKeyboard(tester);
    await waitFor(tester, find.byIcon(Icons.edit_outlined));
    await rawTap(tester, find.byIcon(Icons.edit_outlined).first);
    await waitFor(tester, find.byKey(_kNameField));

    await fillField(tester, _kNameField, 'Edited User');
    await hideKeyboard(tester);

    final saveBtn = find.widgetWithText(FilledButton, 'Save Changes');
    await waitFor(tester, saveBtn);
    await rawTap(tester, saveBtn);
    await pump(tester);

    // 4. Favorite
    // await hideKeyboard(tester);
    // await waitFor(tester, find.byIcon(Icons.favorite_border));
    // await rawTap(tester, find.byIcon(Icons.favorite_border).first);
    // await pump(tester);

    // 5. Search
    await hideKeyboard(tester);
    await fillSearchBar(tester, 'Edited');
    await pump(tester);

    // 6. Clear search
    await fillSearchBar(tester, '');
    await pump(tester);

    // 7. Delete
    await hideKeyboard(tester);
    await waitFor(tester, find.byIcon(Icons.delete_outline));
    await rawTap(tester, find.byIcon(Icons.delete_outline).first);
    await pump(tester);

    // 8. Paginate — scroll to the bottom twice to trigger load_page_2 and
    //    load_page_3. After search_clear above, the observable list is back
    //    to a single page.
    await hideKeyboard(tester);
    await scrollToLoadMore(tester); // → load_page_2
    await scrollToLoadMore(tester); // → load_page_3

    // 9. Back
    await hideKeyboard(tester);
    await waitFor(tester, find.byIcon(Icons.arrow_back));
    await rawTap(tester, find.byIcon(Icons.arrow_back));
    await waitFor(tester, find.text('Choose State Management'));
  }



  // ── Assertions ─────────────────────────────────────────────────────────────

  void assertResults(String library) {
    final results = BenchmarkHarness.instance.resultsFor(library);
    expect(results, isNotEmpty, reason: '$library — no results recorded');
    final events = results.map((r) => r.event).toSet();

    // When the datasource is empty (preset 'none') there's nothing more to
    // paginate through — loadNextPage() returns early on !_hasMore, so
    // load_page_2 / load_page_3 legitimately don't fire. Other events still
    // run (search wraps the action regardless of result size; add/edit/delete
    // operate on rows seeded by the test itself).
    final emptyDataset = BenchmarkConfig.instance.datasetSize == 0;
    final requiredEvents = <String>[
      'load_page_1',
      if (!emptyDataset) 'load_page_2',
      if (!emptyDataset) 'load_page_3',
      'add_user',
      'edit_user',
      'delete_user',
      'search_query',
      'search_clear',
    ];
    for (final e in requiredEvents) {
      expect(events, contains(e), reason: '$library missing event: $e');
    }
    _printTable(library, results);
  }

  // ── Tests ──────────────────────────────────────────────────────────────────
  group('Benchmark Runner — All 4 Libraries', () {
    // Widget types that have RebuildTracker.increment() calls.
    const trackedTypes = {
      'ProviderUserListPage', 'ProviderUserCard',
      'RiverpodUserListPage', 'RiverpodUserCard',
      'GetXUserListPage', 'GetXUserCard',
      'WatchItUserListPage', 'WatchItUserCard',
    };

    setUpAll(() {
      // Preset can be overridden via --dart-define=PRESET=medium|heavy|stress
      const presetName = String.fromEnvironment('PRESET', defaultValue: 'light');
      final preset = switch (presetName) {
        'none' => BenchmarkPreset.none,
        'medium' => BenchmarkPreset.medium,
        'heavy' => BenchmarkPreset.heavy,
        'stress' => BenchmarkPreset.stress,
        _ => BenchmarkPreset.light,
      };
      BenchmarkConfig.instance.applyPreset(preset);
      BenchmarkHarness.instance.clear();

      // Attach the framework tracker (debug mode only — no-op in profile).
      // When running with --profile, the assert() inside start() is stripped
      // and the tracker stays inactive. The harness falls back to the manual
      // RebuildTracker automatically.
      final fwTracker = FrameworkRebuildTracker(trackedTypes: trackedTypes);
      BenchmarkHarness.instance.setFrameworkTracker(fwTracker);
    });

    testWidgets('Riverpod benchmark sequence', (tester) async {
      app.main();
      await pump(tester);
      await runLibrarySequence(tester, 'Riverpod');
      assertResults('riverpod');
    });

    testWidgets('GetX benchmark sequence', (tester) async {
      app.main();
      await pump(tester);
      await runLibrarySequence(tester, 'GetX');
      assertResults('getx');
    });

    testWidgets('Provider benchmark sequence', (tester) async {
      app.main();
      await pump(tester);
      await runLibrarySequence(tester, 'Provider');
      assertResults('provider');
    });

    testWidgets('watch_it benchmark sequence', (tester) async {
      app.main();
      await pump(tester);
      await runLibrarySequence(tester, 'Watch_It');
      assertResults('watch_it');
    });

    testWidgets('Export all results', (tester) async {
      final all = BenchmarkHarness.instance.results;
      expect(
        all,
        isNotEmpty,
        reason: 'No results — did all library tests pass?',
      );
      final dir = await const MetricsExporter().exportAll(all);
      debugPrint('\n╔══════════════════════════════════╗');
      debugPrint('║   BENCHMARK EXPORT COMPLETE      ║');
      debugPrint('║ Dir: $dir');
      debugPrint('║ Total: ${all.length} results');
      debugPrint('╚══════════════════════════════════╝\n');
      _printComparisonTable(all);
    });
  });
}

// ── Console output ─────────────────────────────────────────────────────────

void _printTable(String library, List<BenchmarkResult> results) {
  debugPrint('\n┌──────────────────────────────────────────────┐');
  debugPrint('│ ${library.toUpperCase().padRight(44)} │');
  debugPrint('├──────────────────┬─────────┬─────────┬───────┤');
  debugPrint('│ Event            │   ms    │   KB    │builds │');
  debugPrint('├──────────────────┼─────────┼─────────┼───────┤');
  for (final r in results) {
    debugPrint(
      '│ ${r.event.padRight(16)} '
      '│ ${r.durationMs.toString().padLeft(7)} '
      '│ ${r.rssDeltaKB.toString().padLeft(7)} '
      '│ ${r.rebuildCount.toString().padLeft(5)} │',
    );
  }
  debugPrint('└──────────────────┴─────────┴─────────┴───────┘');
}

void _printComparisonTable(List<BenchmarkResult> all) {
  const libs = ['riverpod', 'getx', 'provider', 'watch_it'];
  const events = [
    'load_page_1',
    'load_page_2',
    'load_page_3',
    'add_user',
    'edit_user',
    'delete_user',
    'search_query',
    'search_clear',
  ];
  debugPrint('\n╔══════════ DURATION ms / REBUILDS ══════════╗');
  debugPrint(
    '║ Event            │ Riverpod │ GetX     │ Provider │ watch_it ║',
  );
  debugPrint(
    '╠══════════════════╪══════════╪══════════╪══════════╪══════════╣',
  );
  for (final event in events) {
    final row = StringBuffer('║ ${event.padRight(16)} │');
    for (final lib in libs) {
      final r = all
          .where((r) => r.library == lib && r.event == event)
          .firstOrNull;
      final cell = r != null ? '${r.durationMs}ms/${r.rebuildCount}' : '—';
      row.write(' ${cell.padRight(8)} │');
    }
    debugPrint(row.toString());
  }
  debugPrint(
    '╚══════════════════╧══════════╧══════════╧══════════╧══════════╝',
  );
}
