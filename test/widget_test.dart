import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/core/strings.dart';
import 'package:lurniq/main.dart';
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
      displayName: 'Widget Tester', username: 'widget_tester');
  return store;
}

void main() {
  Future<void> tapNav(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
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

    // Six default subject folders are seeded.
    expect(find.text('Mathematics'), findsOneWidget);

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

    expect(find.text('Maria Santos'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField).first, 'guitar');
    await tester.pumpAndSettle();
    expect(find.text('Maria Santos'), findsNothing);
    expect(find.text('Diego Fernández'), findsOneWidget);
  });
}
