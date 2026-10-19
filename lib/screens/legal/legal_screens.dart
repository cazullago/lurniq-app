import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../legal/legal_versions.dart';
import '../../store/app_store.dart';

/// Real DRAFT legal documents for the Lurniq tutoring marketplace.
///
/// These are good-faith drafts written for the product — they are NOT legal
/// advice and are NOT final. Every surface shows [LegalDocs.draftBanner].
/// The lawyer-review gate lives in LEGAL_CHECKLIST.md: no real payments
/// before a lawyer signs off.
class LegalDocs {
  static const tosVersion = LegalVersions.tos;
  static const ppVersion = LegalVersions.privacyPolicy;
  static const tutorAgreementVersion = LegalVersions.tutorAgreement;

  static const draftBanner = S.legalDraftBanner;
}

class LegalSection {
  const LegalSection(this.title, this.body);
  final String title;
  final String body;
}

class TosText {
  static const sections = <LegalSection>[
    LegalSection(
      '1. What Lurniq is',
      'Lurniq is a marketplace platform that connects students with independent '
      'tutors and learning resources. Tutors on Lurniq are independent '
      'individuals — not employees, agents, or representatives of Lurniq. '
      'Lurniq provides the platform; the teaching relationship is between the '
      'student and the tutor.',
    ),
    LegalSection(
      '2. Eligibility and minors',
      'Students must be at least 13 years old, or the minimum age required by '
      'their country\'s law, whichever is higher. Students under 18 need a '
      'parent or guardian\'s permission to use paid features. Tutors must be '
      'at least 18 years old and are age-checked at application. To protect '
      'minors: adult tutors may never request private contact details from a '
      'minor, one-on-one sessions with minors require parental awareness, and '
      'any adult–minor interaction that feels unsafe should be reported '
      'immediately — we act on every report.',
    ),
    LegalSection(
      '3. Tutor listings and honesty',
      'Tutors set their own subjects, prices, and availability. Tutors must '
      'describe their qualifications honestly: verified credentials are '
      'labeled as verified, and everything else is shown as self-reported. '
      'Misrepresenting qualifications, faking reviews, or bait-and-switch '
      'pricing leads to removal.',
    ),
    LegalSection(
      '4. Fees and the 15% platform commission',
      'Paid courses and 1v1 bookings carry a platform commission, currently '
      '15%. Example: on a \$20 course, the platform keeps \$3 and the tutor '
      'receives \$17 before payment-processing fees, taxes, or refunds. The '
      'full price, the platform fee, and the tutor\'s share are shown before '
      'any payment is confirmed. Free courses and free tutoring carry no '
      'commission.',
    ),
    LegalSection(
      '5. Tutor payouts',
      'Tutor earnings become available for payout 7 days after the related '
      'session or course enrollment, to cover the refund window. The minimum '
      'payout threshold is \$20 (or local equivalent). Payouts are sent '
      'through our payment provider to the payout method on file. Payouts '
      'begin only after payment processing is enabled; until then all '
      'transactions are disabled.',
    ),
    LegalSection(
      '6. Bookings, cancellations, and refunds',
      'Students: cancel more than 24 hours before a session for a full refund; '
      'cancellations within 24 hours receive a 50% refund. If the tutor '
      'cancels, the student is refunded in full. Courses: full refund within '
      '7 days of enrollment if less than 20% of lessons were opened. Refunds '
      'go to the original payment method. Disputes are reviewed case by case '
      '— contact support.',
    ),
    LegalSection(
      '7. Conduct and academic integrity',
      'Lurniq exists to help students learn, not to complete their assessed '
      'work for them. Tutors must teach and explain; they must not write '
      'students\' graded assignments or sit exams for them. Users must not '
      'post harmful, hateful, or illegal content, harass others, or share '
      'someone\'s private information. Violations lead to warnings, '
      'suspension, or a permanent ban.',
    ),
    LegalSection(
      '8. Reporting and moderation',
      'Every profile, post, message, course, and session can be reported. '
      'Reports are reviewed by our moderation team, and urgent safety '
      'reports are prioritized. Blocking is immediate and always available.',
    ),
    LegalSection(
      '9. Suspension and termination',
      'We may suspend or terminate accounts that break these terms, harm '
      'other users, or misuse the platform — including chargeback fraud and '
      'fake reviews. Users may delete their account at any time from '
      'Settings; deletion removes their on-device data and requests removal '
      'of server-side data where applicable.',
    ),
    LegalSection(
      '10. Liability',
      'Lurniq is provided "as is". We work hard to keep the platform safe '
      'and useful, but we are not liable for the content, conduct, or '
      'teaching quality of independent tutors, nor for learning outcomes. '
      'Nothing here limits rights you have under your local consumer law.',
    ),
    LegalSection(
      '11. Changes',
      'We may update these terms as the product grows (for example when real '
      'payments launch). Material changes will be announced in the app before '
      'they take effect.',
    ),
    LegalSection(
      '12. Contact',
      'Questions about these terms: support@lurniq.app (placeholder — real '
      'support channel before public launch).',
    ),
  ];
}

class PrivacyText {
  static const sections = <LegalSection>[
    LegalSection(
      '1. Data we collect',
      'Account data: display name, username, optional email, profile photo, '
      'country, language, education level, and settings. Content you create: '
      'posts, comments, messages, lesson photos, tasks, courses, bookings, '
      'and reviews. Technical data: device type, app version, and basic '
      'diagnostics. In the current demo build, all of this lives only on '
      'your device.',
    ),
    LegalSection(
      '2. Why we collect it',
      'To run the app (accounts, feeds, planner, tutoring), keep it safe '
      '(moderation, fraud prevention), and improve it (aggregated, '
      'non-identifying analytics). We do not sell personal data.',
    ),
    LegalSection(
      '3. Camera and photos',
      'The camera and photo library are used only when you choose to: lesson '
      'photos in the Planner, post images, profile and course pictures, and '
      'grade photos. Photos stay on your device in the demo build and are '
      'never accessed in the background.',
    ),
    LegalSection(
      '4. Data safety summary',
      'No precise location is collected. No advertising identifiers are '
      'collected. Contacts, calendars, and files outside the app are never '
      'accessed. Payment details, when payments launch, go directly to our '
      'payment provider — Lurniq never sees or stores card numbers.',
    ),
    LegalSection(
      '5. Sharing',
      'We share data only to operate the service: the payment provider for '
      'purchases and payouts (when enabled), and authorities when required '
      'by law. Tutors see only what students share with them in a booking '
      'or course.',
    ),
    LegalSection(
      '6. Retention and deletion',
      'Content is kept while your account is active. Delete your account in '
      'Settings at any time: this wipes your on-device data immediately. '
      'You can also clear demo content separately without deleting your '
      'account.',
    ),
    LegalSection(
      '7. Children and minors',
      'Lurniq is not directed at children under 13. Minor accounts get '
      'restricted messaging, no public precise-location sharing, and '
      'extra moderation. Parents or guardians may request review or '
      'deletion of a minor\'s data via support@lurniq.app.',
    ),
    LegalSection(
      '8. Your rights',
      'Depending on your country (including the Philippines\' Data Privacy '
      'Act of 2012), you may have the right to access, correct, or delete '
      'your personal data, and to object to certain processing. Contact us '
      'and we will respond.',
    ),
    LegalSection(
      '9. Changes',
      'We will announce material privacy changes in the app before they '
      'take effect, especially before any server-side data collection '
      'begins.',
    ),
  ];
}

class TutorAgreementText {
  static const sections = <LegalSection>[
    LegalSection(
      'Independent tutors, honest listings',
      'You teach as an independent tutor, not as a Lurniq employee. List '
      'only subjects you genuinely understand and describe your experience '
      'honestly — verified credentials are labeled; everything else shows '
      'as self-reported.',
    ),
    LegalSection(
      'Commission: 15%',
      'Lurniq keeps a 15% platform commission on paid courses and 1v1 '
      'bookings. Students always see the price, the platform fee, and your '
      'share before paying. This rate can change with notice; the rate '
      'shown at checkout applies.',
    ),
    LegalSection(
      'Payouts',
      'Earnings clear 7 days after the session or enrollment (refund '
      'window). Minimum payout is \$20 or local equivalent, sent through '
      'our payment provider. Payouts start when payment processing is '
      'enabled.',
    ),
    LegalSection(
      'Cancellations and refunds you honor',
      'If you cancel a session, the student is refunded in full. '
      'Student cancellations more than 24 hours ahead get a full refund; '
      'within 24 hours, 50%. Repeated last-minute cancellations by a '
      'tutor lead to removal.',
    ),
    LegalSection(
      'Conduct and academic integrity',
      'Teach, don\'t do their homework: never complete a student\'s graded '
      'assessment for them. No harassment, no private contact with minors '
      'outside the platform, no sharing of student data. Reports against '
      'you are reviewed and can end your listing.',
    ),
    LegalSection(
      'Taxes are yours',
      'You are responsible for reporting and paying your own taxes on '
      'tutor earnings in your country (for example, BIR registration and '
      'filings in the Philippines). Lurniq does not withhold tax for you.',
    ),
  ];
}

/// Shared scaffold: draft banner + version + numbered sections.
class LegalDocScreen extends StatelessWidget {
  const LegalDocScreen({
    super.key,
    required this.title,
    required this.version,
    required this.sections,
  });

  final String title;
  final String version;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gavel_rounded,
                    color: scheme.onTertiaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LegalDocs.draftBanner,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${S.legalVersion}: $version',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          for (final s in sections) ...[
            Text(
              s.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(s.body, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 18),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Ensures the Tutor Agreement is accepted, presenting the agreement
/// screen when needed. Returns true if the caller may proceed with
/// listing (course / live session). Used by the tutor listing forms.
Future<bool> ensureTutorAgreement(BuildContext context) async {
  final store = context.read<AppStore>();
  if (store.tutorAgreementAccepted) return true;
  final accepted = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => const TutorAgreementScreen(acceptMode: true),
    ),
  );
  if (accepted == true && context.mounted) {
    return context.read<AppStore>().tutorAgreementAccepted;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(S.agreementRequired)),
    );
  }
  return false;
}

class TosScreen extends StatelessWidget {
  const TosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocScreen(
      title: S.termsOfService,
      version: LegalDocs.tosVersion,
      sections: TosText.sections,
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocScreen(
      title: S.privacyPolicy,
      version: LegalDocs.ppVersion,
      sections: PrivacyText.sections,
    );
  }
}

/// Tutor Agreement: summary a tutor must accept before listing courses,
/// live sessions, or 1v1 bookings. Rendered with an optional accept row.
class TutorAgreementScreen extends StatefulWidget {
  const TutorAgreementScreen({super.key, this.acceptMode = false});

  /// When true, shows the acceptance checkbox + button at the bottom.
  final bool acceptMode;

  @override
  State<TutorAgreementScreen> createState() =>
      _TutorAgreementScreenState();
}

class _TutorAgreementScreenState extends State<TutorAgreementScreen> {
  bool _agreed = false;
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await context.read<AppStore>().acceptTutorAgreement();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(S.agreementAccepted)),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.tutorAgreementTitle)),
      body: Column(
        children: [
          const Expanded(
            child: LegalDocScreen(
              title: S.tutorAgreementTitle,
              version: LegalDocs.tutorAgreementVersion,
              sections: TutorAgreementText.sections,
            ),
          ),
          if (widget.acceptMode)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      value: _agreed,
                      onChanged: (v) =>
                          setState(() => _agreed = v ?? false),
                      title: const Text(S.tutorAgreementAccept),
                      controlAffinity:
                          ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    FilledButton(
                      onPressed:
                          (_agreed && !_busy) ? _accept : null,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Text(S.acceptAgreement),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
