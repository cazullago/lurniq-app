import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/notify_service.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'quiz_builder.dart';
import 'quiz_runner.dart';

/// Detail for one 1v1 booking: status, time, meeting link, and the
/// demo-mode "tutor response" row for pending requests. Accepted bookings
/// show a join button + practice quiz; completed ones accept a review.
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme.isEmpty) {
      showSnack(context, 'That meeting link doesn\u2019t look valid.');
      return;
    }
    final ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showSnack(context, 'Couldn\u2019t open the meeting link.');
    }
  }

  Future<void> _respond(
      BuildContext context, TutorBooking booking, bool accept) async {
    final store = context.read<AppStore>();
    await store.setBookingStatus(
        booking.id, accept ? 'accepted' : 'declined');
    if (accept && booking.startsAtUtc != null) {
      await NotifyService.instance.scheduleAt(
        at: booking.startsAtUtc!
            .subtract(const Duration(minutes: 15)),
        title: S.bookingReminderTitle,
        body: S.bookingReminderBody,
      );
    }
    if (context.mounted) {
      showSnack(
          context, accept ? S.bookingAccepted : S.bookingDeclined);
    }
  }

  void _review(BuildContext context, TutorBooking booking) {
    final text = TextEditingController();
    double rating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(S.leaveReview),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    hintText: S.reviewHint,
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
                await context.read<AppStore>().leaveBookingReview(
                      booking.id,
                      rating: rating,
                      text: text.text,
                    );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  showSnack(context, S.reviewThanks);
                }
              },
              child: const Text(S.leaveReview),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final booking = store.bookingById(bookingId);
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.event_busy_outlined,
          title: S.somethingWrong,
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final me = store.currentUser;
    final local = booking.startsAtUtc == null
        ? null
        : utcToViewer(booking.startsAtUtc!, me);
    return Scaffold(
      appBar: AppBar(title: Text(S.myBookings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '1v1 with ${booking.tutorName}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StatusChip(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Row(
                    icon: Icons.schedule_outlined,
                    label: local == null
                        ? 'No time set'
                        : fmtDateTime(local),
                  ),
                  _Row(
                    icon: Icons.timer_outlined,
                    label: '${booking.durationMin} ${S.minutes}',
                  ),
                  if (booking.note.isNotEmpty)
                    _Row(
                      icon: Icons.note_outlined,
                      label: booking.note,
                    ),
                  if (booking.meetingLink.isNotEmpty)
                    _Row(
                      icon: Icons.videocam_outlined,
                      label: booking.meetingLink,
                    ),
                ],
              ),
            ),
          ),
          if (booking.status == 'pending') ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo tutor response',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demo mode: the tutor is simulated on this device. Tap a response to continue the flow.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _respond(context, booking, false),
                            child: const Text(S.decline),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                _respond(context, booking, true),
                            child: const Text(S.accept),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (booking.status == 'accepted') ...[
            const SizedBox(height: 8),
            if (booking.meetingLink.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _launch(context, booking.meetingLink),
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text(S.joinMeeting),
                ),
              )
            else
              const Text(
                  'No meeting link yet — the tutor adds it before the session.'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice quiz',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Build a quick ad-hoc quiz to warm up before your session.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: () =>
                          Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _PracticeQuizScreen(
                              bookingId: booking.id),
                        ),
                      ),
                      child: const Text(S.createQuiz),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (booking.status == 'completed') ...[
            const SizedBox(height: 8),
            if (booking.reviewRating == 0)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _review(context, booking),
                  child: const Text(S.leaveReview),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarsRow(
                          rating: booking.reviewRating, size: 18),
                      if (booking.reviewText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(booking.reviewText),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    switch (status) {
      case 'accepted':
        bg = Colors.green.withValues(alpha: 0.15);
      case 'declined':
      case 'cancelled':
        bg = scheme.errorContainer;
      case 'completed':
        bg = scheme.primaryContainer;
      default:
        bg = Colors.orange.withValues(alpha: 0.15);
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// Build-then-run screen for an ad-hoc practice quiz on a booking.
class _PracticeQuizScreen extends StatefulWidget {
  const _PracticeQuizScreen({required this.bookingId});

  final String bookingId;

  @override
  State<_PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<_PracticeQuizScreen> {
  List<QuizQuestion> _questions = [];

  @override
  Widget build(BuildContext context) {
    final valid = QuizBuilder.validate(_questions);
    return Scaffold(
      appBar: AppBar(title: const Text('Practice quiz')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          QuizBuilder(
            questions: const [],
            onChanged: (qs) =>
                setState(() => _questions = qs),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: valid
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizRunner(
                          quiz: _questions,
                          sessionId:
                              'booking-${widget.bookingId}',
                          title: 'Practice quiz',
                        ),
                      ),
                    )
                : null,
            child: const Text(S.startQuiz),
          ),
          if (!valid && _questions.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Finish every question first: text, at least 2 options, and one marked correct answer.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
