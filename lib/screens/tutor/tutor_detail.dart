import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'booking_form_screen.dart';

/// Tutor profile detail. Reviews + 1v1 booking requests.
class TutorDetailScreen extends StatelessWidget {
  const TutorDetailScreen({super.key, required this.tutorId});

  final String tutorId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final tutor = store.tutorById(tutorId);
    if (tutor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: S.somethingWrong,
        ),
      );
    }
    final reviews = store.reviewsFor(tutorId);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tutor.name),
        actions: [if (tutor.isDemo) const DemoChip()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(tutor.colorValue).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    UserAvatar(
                        name: tutor.name,
                        colorValue: tutor.colorValue,
                        radius: 44),
                    if (tutor.onlineNow)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: scheme.surface, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tutor.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VerificationBadge(status: tutor.verification),
                    const SizedBox(width: 8),
                    PriceTag(priceUsd: tutor.priceUsd),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StarsRow(rating: tutor.rating, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${tutor.reviewCount} ${S.reviewsCount}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (tutor.onlineNow) ...[
                  const SizedBox(height: 6),
                  Text(
                    S.tutorOnline,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _InfoCard(
            title: S.tutorTeaches,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tutor.subjects
                  .map((s) => Chip(label: Text(s)))
                  .toList(),
            ),
          ),
          _InfoCard(
            title: S.tutorExperience,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tutor.intro),
                if (tutor.experience.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(tutor.experience,
                      style: TextStyle(
                          color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 8),
                _Row(
                    icon: Icons.translate_outlined,
                    label: S.tutorLanguages,
                    value: tutor.languages.join(', ')),
                _Row(
                    icon: Icons.public_outlined,
                    label: S.tutorLocation,
                    value: tutor.country),
                _Row(
                    icon: Icons.schedule_outlined,
                    label: S.tutorAvailability,
                    value: tutor.availability),
                _Row(
                    icon: Icons.school_outlined,
                    label: S.tutorLevel,
                    value: tutor.levels.join(', ')),
              ],
            ),
          ),
          if (tutor.qualifications case final q? when q.isNotEmpty)
            _InfoCard(
              title: S.tutorQualifications,
              child: Text(q),
            ),
          _InfoCard(
            title: S.verificationTitle,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VerificationBadge(status: tutor.verification),
                const SizedBox(width: 10),
                Expanded(child: Text(_verificationDetail(tutor.verification))),
              ],
            ),
          ),
          _InfoCard(
            title: S.tutorReviews,
            trailing: TextButton(
              onPressed: () => _writeReview(context, tutor),
              child: const Text(S.writeReview),
            ),
            child: reviews.isEmpty
                ? Text(S.noReviewsYet,
                    style: TextStyle(color: scheme.onSurfaceVariant))
                : Column(
                    children: reviews
                        .map((r) => _ReviewTile(review: r))
                        .toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingFormScreen(
                    tutorId: tutor.id,
                    tutorName: tutor.name,
                  ),
                ),
              ),
              child: const Text(S.bookSession),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Text(
              S.commissionNote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _verificationDetail(String status) {
    switch (status) {
      case 'id':
        return S.verificationIdDetail;
      case 'credential':
        return S.verificationCredentialDetail;
      default:
        return S.verificationUnverifiedDetail;
    }
  }

  void _writeReview(BuildContext context, Tutor tutor) {
    final text = TextEditingController();
    double rating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(S.writeReview),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.yourRating,
                    style: Theme.of(ctx)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber[700],
                        size: 32,
                      ),
                      onPressed: () =>
                          setState(() => rating = i + 1.0),
                    ),
                  ),
                ),
                TextField(
                  controller: text,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: S.yourReview,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(S.cancel),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await context.read<AppStore>().addTutorReview(
                        tutorId: tutor.id,
                        rating: rating,
                        text: text.text,
                      );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    showSnack(context, S.reviewThanks);
                  }
                } on StoreException catch (e) {
                  if (ctx.mounted) showSnack(ctx, e.message);
                }
              },
              child: const Text(S.publish),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing case final Widget t) t,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.secondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final TutorReview review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(name: review.authorName, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    StarsRow(rating: review.rating, size: 12),
                  ],
                ),
                const SizedBox(height: 2),
                Text(review.text),
                const SizedBox(height: 2),
                Text(
                  timeAgo(review.createdAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
