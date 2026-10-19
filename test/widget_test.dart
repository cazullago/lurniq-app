import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/core/options.dart';
import 'package:lurniq/core/strings.dart';
import 'package:lurniq/main.dart';
import 'package:lurniq/models/models.dart';
import 'package:lurniq/store/app_store.dart';

/// End-to-end widget tests for the critical Phase 1 flows, driven through
/// the real UI on top of a real (in-memory) store. Widget tests use
/// [AppStore.loadForTest]: real async file IO deadlocks inside testWidgets'
/// FakeAsync zone, so the disk is never touched here. Disk persistence is
/// covered by store_test.dart (pure tests, real async zone).
Future<AppStore> freshStore() => AppStore.loadForTest();

Future<AppStore> signedInStore() async {
  final store = await AppStore.loadForTest();
  await store.signUp(
      displayName: 'Widget Tester', username: 'widget_tester', tosAccepted: true, ppAccepted: true);
  return store;
}

void main() {
  /// Tap a bottom-nav item. The first nav tap in a testWidgets run is
  /// sometimes swallowed by the test framework's hit testing (no real-device
  /// impact), so verify the switch and retry once if it didn't land.
  Future<void> tapNav(WidgetTester tester, String label) async {
    final target = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );
    BottomNavigationBar bar() =>
        tester.widget(find.byType(BottomNavigationBar));
    final items = bar()
        .items
        .map((i) => (i.label ?? ''))
        .toList();
    final want = items.indexOf(label);
    await tester.tap(target, warnIfMissed: false);
    await tester.pumpAndSettle();
    if (bar().currentIndex != want) {
      await tester.tap(target, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
      'auth flow: create account lands on the five main tabs',
      (tester) async {
    final store = await freshStore();
    await tester.pumpWidget(LurniqApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text(S.welcomeTitle), findsOneWidget);

    await tester.tap(find.text(S.createAccount).first);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).at(0), 'Widget Tester');
    await tester.enterText(
        find.byType(TextField).at(1), 'widget_tester');
    // Legal acceptance is required before sign-up (v2).
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    await tester.tap(
        find.widgetWithText(FilledButton, S.createAccount));
    await tester.pumpAndSettle();

    // Exactly five bottom navigation buttons, starting on the Newsfeed.
    final navBar = find.byType(BottomNavigationBar);
    for (final label in [
      S.navTutor,
      S.navNewsfeed,
      S.navAddPost,
      S.navPlanner,
      S.navProfile,
    ]) {
      expect(
          find.descendant(
              of: navBar, matching: find.text(label)),
          findsOneWidget);
    }
    expect(
        find.descendant(
            of: find.byType(AppBar),
            matching: find.text(S.feedTitle)),
        findsOneWidget);
  });

  testWidgets('compose flow: post published appears in the newsfeed',
      (tester) async {
    final store = await signedInStore();
    await tester.pumpWidget(LurniqApp(store: store));
    await tester.pumpAndSettle();

    await tapNav(tester, S.navAddPost);
    await tester.tap(find.text(S.optionGeneralPost));
    await tester.pumpAndSettle();

    const body =
        'Widget-test question about photosynthesis 12345';
    await tester.enterText(
        find.byType(TextField).at(1), body);
    // Two "Preview" labels exist (AppBar action + bottom button, the
    // latter off-screen). Tap the AppBar action.
    await tester.tap(
        find.widgetWithText(TextButton, S.preview));
    await tester.pumpAndSettle();

    expect(find.text(body), findsOneWidget);
    await tester.tap(find.text(S.publishPost));
    await tester.pumpAndSettle();

    await tapNav(tester, S.navNewsfeed);
    expect(find.text(body), findsOneWidget);
  });

  testWidgets('planner flow: create a subject folder', (tester) async {
    final store = await signedInStore();
    await tester.pumpWidget(LurniqApp(store: store));
    await tester.pumpAndSettle();

    await tapNav(tester, S.navPlanner);

    // Six default subject folders are seeded (name shows on the folder
    // card and in the task filter chips).
    expect(find.text('Mathematics'), findsWidgets);

    await tester.tap(find.text(S.newFolder));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).first, 'Astronomy');
    await tester.tap(find.text(S.save));
    await tester.pumpAndSettle();
    expect(find.text('Astronomy'), findsOneWidget);
  });

  testWidgets('planner flow: create a task', (tester) async {
    final store = await signedInStore();
    await tester.pumpWidget(LurniqApp(store: store));
    await tester.pumpAndSettle();

    await tapNav(tester, S.navPlanner);

    // Tasks inner tab — tapped before any dialog is shown in this test.
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    // The empty state also shows a "New task" button — target the FAB.
    await tester.tap(find.widgetWithText(FloatingActionButton, S.newTask));
    await tester.pumpAndSettle();

    const taskTitle = 'Widget-test task: read chapter 3';
    await tester.enterText(find.byType(TextField).first, taskTitle);
    await tester.tap(find.text(S.saveTask));
    await tester.pumpAndSettle();
    expect(find.text(taskTitle), findsOneWidget);
  });

  testWidgets('tutor tab: search filters the directory',
      (tester) async {
    final store = await signedInStore();
    await tester.pumpWidget(LurniqApp(store: store));
    await tester.pumpAndSettle();

    await tapNav(tester, S.navTutor);

    // v2 tutor cards are tall; the directory is lazily built, so drag
    // until Maria's card is on screen.
    for (var i = 0;
        i < 6 && find.text('Maria Santos').evaluate().isEmpty;
        i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(find.text('Maria Santos'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField).first, 'guitar');
    await tester.pumpAndSettle();
    expect(find.text('Maria Santos'), findsNothing);
    // Scroll Diego into view before asserting.
    for (var i = 0;
        i < 6 && find.text('Diego Fernández').evaluate().isEmpty;
        i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(find.text('Diego Fernández'), findsOneWidget);
  });

  testWidgets('settings: appearance theme toggle persists',
      (tester) async {
    final store = await signedInStore();
    await tester.pumpWidget(LurniqApp(store: store));
    await tester.pumpAndSettle();

    await tapNav(tester, S.navProfile);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(store.themeModeSetting, ThemeModeSetting.system);

    await tester.ensureVisible(find.text(S.themeLight));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.themeLight));
    await tester.pumpAndSettle();

    expect(store.themeModeSetting, ThemeModeSetting.light);
    expect(store.currentUser!.themeMode, 'light');

    // Persisted on the user record, so a reload keeps it.
    final reloaded =
        AppUser.fromJson(store.currentUser!.toJson());
    expect(reloaded.themeMode, 'light');
  });

  testWidgets('edit profile: education level saves via edit flow',
      (tester) async {
    final store = await signedInStore();
    await tester.pumpWidget(LurniqApp(store: store));
    await tester.pumpAndSettle();

    await tapNav(tester, S.navProfile);
    await tester.tap(find.text(S.editProfile));
    await tester.pumpAndSettle();

    // Country is the first OptionField, education level the second.
    final fields = find.byType(OptionField);
    expect(fields, findsNWidgets(2));
    await tester.ensureVisible(fields.at(1));
    await tester.pumpAndSettle();
    await tester.tap(fields.at(1));
    await tester.pumpAndSettle();

    // Option sheet is open; pick a value (also verifies the
    // "Other…" free-text row exists on this list).
    expect(find.text('Other…'), findsOneWidget);
    await tester.tap(find.text('College'));
    await tester.pumpAndSettle();

    // Selection is reflected in the field before saving.
    expect(find.text('College'), findsOneWidget);
    expect(store.currentUser!.educationLevel, isEmpty);

    // Save from the app bar and confirm the store persisted it.
    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.text(S.save),
    ));
    await tester.pumpAndSettle();
    expect(store.currentUser!.educationLevel, 'College');
  });
}
