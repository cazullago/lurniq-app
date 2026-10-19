import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/core/strings.dart';
import 'package:lurniq/screens/profile/settings_screen.dart';
import 'package:lurniq/screens/profile/subscription_screen.dart';
import 'package:lurniq/store/app_store.dart';
import 'package:provider/provider.dart';

/// Smoke test for the redesigned Settings screen: visual theme chips,
/// wash-grouped sections, and the Subscription row.
///
/// Uses a tall test viewport so no scrolling is needed (deterministic taps).
void main() {
  Future<AppStore> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    final store = await AppStore.loadForTest();
    await store.signUp(
        displayName: 'Dbg',
        username: 'dbg',
        tosAccepted: true,
        ppAccepted: true);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('theme chips render and Day chip persists the theme',
      (tester) async {
    final store = await pumpSettings(tester);
    addTearDown(tester.view.resetPhysicalSize);

    expect(find.text(S.themeSystem), findsOneWidget);
    expect(find.text(S.themeLight), findsOneWidget);
    expect(find.text(S.themeDark), findsOneWidget);

    await tester.tap(find.text(S.themeLight));
    await tester.pumpAndSettle();
    expect(store.themeModeSetting, ThemeModeSetting.light);
    expect(store.currentUser!.themeMode, 'light');

    await tester.tap(find.text(S.themeDark));
    await tester.pumpAndSettle();
    expect(store.themeModeSetting, ThemeModeSetting.dark);
  });

  testWidgets('subscription row opens the Subscription screen',
      (tester) async {
    await pumpSettings(tester);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.tap(find.text(S.subscription));
    await tester.pumpAndSettle();

    expect(find.byType(SubscriptionScreen), findsOneWidget);
    expect(find.text(S.plusMonthly), findsOneWidget);
    expect(find.text(S.plusYearly), findsOneWidget);
    expect(find.text(S.bestValue), findsOneWidget);
    expect(find.text(S.subscribe), findsNWidgets(2));

    // Subscribe buttons are placeholders: coming-soon dialog, no payment.
    await tester.tap(find.text(S.subscribe).first);
    await tester.pumpAndSettle();
    expect(find.text(S.comingSoon), findsOneWidget);
    expect(find.text(S.comingSoonNote), findsOneWidget);
  });
}
