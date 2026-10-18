import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'quiz_runner.dart';

/// Status-aware live session room:
/// - scheduled: countdown, meeting link, quiz question count
/// - live: meeting link + quiz runner (tutor "Start quiz", viewers "Join quiz") + scoreboard
/// - ended: scoreboard
class LiveRoomScreen extends StatefulWidget {
  const LiveRoomScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
        const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _openLink(BuildContext context, String url) async {
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

  void _openQuiz(BuildContext context, LiveSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizRunner(
          quiz: session.quiz,
          sessionId: session.id,
          title: session.title,
        ),
      ),
    );
  }

  String _countdown(DateTime? startsAt) {
    if (startsAt == null) return 'No start time set.';
    final diff = startsAt.difference(DateTime.now());
    if (diff.isNegative) return 'Starting any moment…';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    if (d > 0) return 'Starts in $d d $h h $m m';
    if (h > 0) return 'Starts in $h h $m m';
    return 'Starts in $m m';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final session = store.liveSessionById(widget.sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.live_tv_outlined,
          title: S.somethingWrong,
        ),
      );
    }
    final me = store.currentUser;
    final isOwner = me != null && me.id == session.tutorId;
    final local = session.startsAtUtc == null
        ? null
        : utcToViewer(session.startsAtUtc!, me);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(session.title),
        actions: [if (session.isDemo) const DemoChip()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session.status == 'live')
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record,
                      color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    S.liveNow,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hosted by ${session.tutorName}'
                    '${session.subject.isNotEmpty ? ' · ${session.subject}' : ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            color: scheme.onSurfaceVariant),
                  ),
                  if (session.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(session.description),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          local == null
                              ? 'No time set'
                              : '${fmtDateTime(local)} · ${session.durationMin} ${S.minutes}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.quiz_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        session.quiz.isEmpty
                            ? 'No quiz attached'
                            : '${session.quiz.length} quiz question${session.quiz.length == 1 ? '' : 's'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (session.status == 'scheduled') ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        size: 44),
                    const SizedBox(height: 10),
                    Text(
                      _countdown(session.startsAtUtc),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    if (session.meetingLink.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => _openLink(
                            context, session.meetingLink),
                        icon: const Icon(
                            Icons.videocam_outlined),
                        label: const Text(S.openMeetingLink),
                      )
                    else
                      Text(
                        'Meeting link will appear here when the tutor shares it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant),
                      ),
                    if (isOwner) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            await store.setLiveStatus(
                                session.id, 'live');
                            if (context.mounted) {
                              showSnack(
                                  context, 'You are live!');
                            }
                          },
                          child: const Text(S.goLive),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (session.status == 'live') ...[
            const SizedBox(height: 12),
            if (session.meetingLink.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _openLink(context, session.meetingLink),
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text(S.openMeetingLink),
                ),
              ),
            const SizedBox(height: 8),
            if (session.quiz.isEmpty)
              Text(
                'No quiz for this session — just join the meeting link above.',
                style:
                    TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => _openQuiz(context, session),
                  child: Text(
                      isOwner ? S.startQuiz : 'Join quiz'),
                ),
              ),
            if (isOwner) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: S.endSession,
                      body: 'End this live session for everyone?',
                      destructive: false,
                    );
                    if (ok && context.mounted) {
                      await store.setLiveStatus(
                          session.id, 'ended');
                    }
                  },
                  child: const Text(S.endSession),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _Scoreboard(sessionId: session.id),
          ],
          if (session.status == 'ended') ...[
            const SizedBox(height: 12),
            Text(
              'This session has ended.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _Scoreboard(sessionId: session.id),
          ],
        ],
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final attempts =
        context.watch<AppStore>().attemptsFor(sessionId);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.scoreboard,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (attempts.isEmpty)
          Text(
            'No quiz attempts yet.',
            style:
                TextStyle(color: scheme.onSurfaceVariant),
          )
        else
          ...List.generate(attempts.length, (i) {
            final a = attempts[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: i == 0
                      ? Colors.amber.withValues(alpha: 0.25)
                      : scheme.surfaceContainerHighest,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800)),
                ),
                title: Text(a.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700)),
                trailing: Text(
                  '${a.score}/${a.total}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
              ),
            );
          }),
      ],
    );
  }
}
