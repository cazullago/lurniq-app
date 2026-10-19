import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import '../legal/legal_screens.dart';

/// Entry screen for signed-out users. Clearly labeled demo mode: accounts
/// live on this device only ([BACKEND] wires Firebase Auth later).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 56,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                S.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                S.tagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              const Center(child: DemoChip()),
              const SizedBox(height: 8),
              Text(
                S.demoMode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                S.welcomeTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                S.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
                child: const Text(S.createAccount),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                ),
                child: const Text(S.signIn),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _demoSignIn(context),
                child: const Text(S.exploreDemo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _demoSignIn(BuildContext context) async {
    try {
      await context.read<AppStore>().signInDemo();
    } on StoreException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  bool _tosOk = false;
  bool _ppOk = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_tosOk || !_ppOk) {
      showSnack(context, S.mustAcceptLegal);
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AppStore>().signUp(
            displayName: _name.text,
            username: _username.text,
            email: _email.text,
            tosAccepted: _tosOk,
            ppAccepted: _ppOk,
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on StoreException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDoc(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.createAccount)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: DemoChip()),
            const SizedBox(height: 8),
            Text(
              S.demoMode,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: S.displayName,
                hintText: 'Alex Rivera',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _username,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: S.username,
                hintText: 'alex_rivera',
                prefixText: '@',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: S.emailOptional,
              ),
            ),
            const SizedBox(height: 16),
            _LegalCheck(
              value: _tosOk,
              onChanged: (v) => setState(() => _tosOk = v ?? false),
              label: S.tosAccept,
              docLabel: S.termsOfService,
              onOpenDoc: () => _openDoc(const TosScreen()),
            ),
            _LegalCheck(
              value: _ppOk,
              onChanged: (v) => setState(() => _ppOk = v ?? false),
              label: S.ppAccept,
              docLabel: S.privacyPolicy,
              onOpenDoc: () => _openDoc(const PrivacyScreen()),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: (_busy || !_tosOk || !_ppOk) ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(S.createAccount),
            ),
          ],
        ),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _username = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context.read<AppStore>().signIn(_username.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on StoreException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.signIn)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: DemoChip()),
            const SizedBox(height: 24),
            TextField(
              controller: _username,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: S.username,
                prefixText: '@',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(S.signIn),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkbox row for legal acceptance with a tappable "Read" link that opens
/// the full document. Sign-up stays disabled until all boxes are checked.
class _LegalCheck extends StatelessWidget {
  const _LegalCheck({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.docLabel,
    required this.onOpenDoc,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String docLabel;
  final VoidCallback onOpenDoc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(label),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onOpenDoc,
                  child: Text(
                    '${S.readDocument} $docLabel',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
