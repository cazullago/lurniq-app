import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import '../legal/legal_screens.dart';

/// "Become a tutor" — Phase 1 collects interest for the Phase 3 launch.
/// The entry bar stays low by design; verification labels stay honest.
class BecomeTutorScreen extends StatefulWidget {
  const BecomeTutorScreen({super.key});

  @override
  State<BecomeTutorScreen> createState() => _BecomeTutorScreenState();
}

class _BecomeTutorScreenState extends State<BecomeTutorScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _subjects = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _subjects.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context.read<AppStore>().addTutorInterest(
            name: _name.text,
            contact: _contact.text,
            subjects: _subjects.text,
          );
      if (mounted) {
        showSnack(context, S.interestSaved);
        Navigator.of(context).pop();
      }
    } on StoreException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(S.becomeTutorTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: scheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  const Expanded(child: Text(S.becomeTutorBody)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.gavel_rounded),
              label: const Text(S.reviewAgreement),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TutorAgreementScreen(
                      acceptMode: true,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              S.agreementRequired,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              S.tutorInterestTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              S.tutorInterestBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(labelText: S.displayName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contact,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: S.contactInfo),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjects,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: S.whatTeach),
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
                  : const Text(S.notifyMe),
            ),
          ],
        ),
      ),
    );
  }
}
