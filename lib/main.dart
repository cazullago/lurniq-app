import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/compose/compose_tab.dart';
import 'screens/feed/feed_tab.dart';
import 'screens/planner/planner_tab.dart';
import 'screens/profile/profile_tab.dart';
import 'screens/tutor/tutor_tab.dart';
import 'services/notify_service.dart';
import 'store/app_store.dart';

/// Crash-proof bootstrap (see AGENTS.md):
/// - [WidgetsFlutterBinding.ensureInitialized], all async init, and [runApp]
///   execute in ONE zone ([runZonedGuarded]'s body).
/// - The zone's onError handler only logs — it never calls runApp (it runs in
///   the parent zone; calling runApp there reintroduces the zone mismatch).
/// - Any init failure renders an in-app error screen (message + stack snippet
///   + Copy details + Retry) instead of a silent "keeps stopping".
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        debugPrint('FlutterError: ${details.exception}');
      };
      await _boot();
    },
    (error, stack) {
      debugPrint('Uncaught async error: $error\n$stack');
    },
  );
}

Future<void> _boot() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final store = await AppStore.load(dir);
    // Local notifications must never break startup: guarded separately.
    try {
      await NotifyService.instance.init();
    } catch (e) {
      debugPrint('NotifyService.init failed (non-fatal): $e');
    }
    runApp(LurniqApp(store: store));
  } catch (e, st) {
    runApp(BootErrorApp(error: e, stack: st, onRetry: _boot));
  }
}

class LurniqApp extends StatelessWidget {
  const LurniqApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: Builder(
        builder: (ctx) {
          final setting = ctx.watch<AppStore>().themeModeSetting;
          final mode = switch (setting) {
            ThemeModeSetting.light => ThemeMode.light,
            ThemeModeSetting.dark => ThemeMode.dark,
            ThemeModeSetting.system => ThemeMode.system,
          };
          return MaterialApp(
            title: S.appName,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            debugShowCheckedModeBanner: false,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStore>().currentUser;
    if (user == null) return const WelcomeScreen();
    return const MainScreen();
  }
}

/// Exactly five bottom navigation buttons — no parent dashboard.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 1; // start on the Newsfeed
  DateTime? _lastProfileTap;
  int _profileTapCount = 0;

  /// Tab pages created once so tab switches cross-fade without losing
  /// scroll positions or form state.
  late final List<Widget> _tabs = [
    const TutorTab(),
    FeedTab(onCompose: () => setState(() => _index = 2)),
    const ComposeTab(),
    const PlannerTab(),
    const ProfileTab(),
  ];

  void _onTap(int index) {
    if (index == 4) {
      final now = DateTime.now();
      if (_lastProfileTap != null &&
          now.difference(_lastProfileTap!) <
              const Duration(milliseconds: 700)) {
        _profileTapCount++;
      } else {
        _profileTapCount = 1;
      }
      _lastProfileTap = now;
      if (_profileTapCount >= 3) {
        _profileTapCount = 0;
        // Hidden admin entry. The passcode gate (not the gesture) is the
        // real protection on this demo build; production needs server-side
        // admin roles (see README).
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const AdminLoginScreen()),
        );
      }
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // One tab visible at a time; the rest stay alive but offstage so
      // state (scroll, forms) is preserved and hidden tabs stay out of
      // the semantics/finder tree. The active tab fades in subtly.
      body: Stack(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Offstage(
              offstage: i != _index,
              child: IgnorePointer(
                ignoring: i != _index,
                child: AnimatedOpacity(
                  opacity: i == _index ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: _tabs[i],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school_rounded),
            label: S.navTutor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum_rounded),
            label: S.navNewsfeed,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: S.navAddPost,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: S.navPlanner,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: S.navProfile,
          ),
        ],
      ),
    );
  }
}

/// In-app error screen: the app never dies silently on startup.
class BootErrorApp extends StatelessWidget {
  const BootErrorApp({
    super.key,
    required this.error,
    required this.stack,
    required this.onRetry,
  });

  final Object error;
  final StackTrace stack;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final details = 'Error: $error\n\nStack trace:\n$stack';
    final snippet = stack
        .toString()
        .split('\n')
        .take(10)
        .join('\n');
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  S.bootErrorTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  S.bootErrorBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black
                        .withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        error.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snippet,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(
                      Icons.copy_rounded),
                  label:
                      const Text(S.copyDetails),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(
                            text: details));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                          content:
                              Text(S.copied)),
                    );
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(
                      Icons.refresh_rounded),
                  label: const Text(S.retry),
                  onPressed: () => onRetry(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
