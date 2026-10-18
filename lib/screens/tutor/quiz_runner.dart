import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';

/// Reusable quiz runner: one question at a time with a per-question
/// countdown ([QuizQuestion.secondsPerQuestion]).
///
/// Rules: tapping an option gives immediate Correct!/Not quite feedback but
/// never reveals which answer is right — the correct answer is only
/// highlighted when the timer ends ([S.answersHiddenNote]). When every
/// question is done the attempt is submitted via
/// [AppStore.submitQuizAttempt] and a score screen appears.
///
/// Used by live sessions (viewers and tutors) and the 1v1 booking practice
/// quiz. [sessionId] is the live session id, or `booking-<id>` for practice.
class QuizRunner extends StatefulWidget {
  const QuizRunner({
    super.key,
    required this.quiz,
    required this.sessionId,
    this.title,
  });

  final List<QuizQuestion> quiz;
  final String sessionId;
  final String? title;

  @override
  State<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<QuizRunner> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _revealed = false;
  bool _done = false;
  bool _submitted = false;
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.quiz.isNotEmpty) {
      _startQuestion();
    } else {
      _done = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startQuestion() {
    _timer?.cancel();
    final q = widget.quiz[_index];
    setState(() {
      _selected = null;
      _answered = false;
      _revealed = false;
      _remaining = q.secondsPerQuestion > 0 ? q.secondsPerQuestion : 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        _onTimeUp();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _onTimeUp() {
    if (!mounted || _revealed || _done) return;
    setState(() => _revealed = true);
    // Reveal the correct answer briefly, then move on.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _advance();
    });
  }

  void _onAnswer(int i) {
    if (_answered || _revealed || _done) return;
    final q = widget.quiz[_index];
    setState(() {
      _answered = true;
      _selected = i;
      if (i == q.correctIndex) _score++;
    });
  }

  void _advance() {
    if (_done || !mounted) return;
    if (_index + 1 >= widget.quiz.length) {
      _finish();
    } else {
      _index++;
      _startQuestion();
    }
  }

  void _finish() {
    _timer?.cancel();
    if (_submitted) return;
    _submitted = true;
    final me = context.read<AppStore>().currentUser;
    context.read<AppStore>().submitQuizAttempt(QuizAttempt(
          id: newId(),
          sessionId: widget.sessionId,
          userId: me?.id ?? 'guest',
          userName: me?.displayName ?? 'Guest',
          score: _score,
          total: widget.quiz.length,
        ));
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? S.liveQuiz)),
      body: _done ? _scoreScreen(scheme) : _questionScreen(scheme),
    );
  }

  Widget _questionScreen(ColorScheme scheme) {
    final q = widget.quiz[_index];
    final total = q.secondsPerQuestion > 0 ? q.secondsPerQuestion : 30;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Question ${_index + 1} of ${widget.quiz.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _remaining <= 5
                    ? scheme.errorContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_remaining s',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _remaining <= 5
                      ? scheme.onErrorContainer
                      : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total == 0 ? 0 : _remaining / total,
          borderRadius: BorderRadius.circular(8),
          minHeight: 8,
        ),
        const SizedBox(height: 20),
        Text(
          q.question,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...List.generate(q.options.length, (i) {
          final isCorrect = _revealed && i == q.correctIndex;
          final isPicked = _selected == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.tonal(
              key: Key('quiz-option-$i'),
              style: FilledButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                backgroundColor: isCorrect
                    ? Colors.green.withValues(alpha: 0.25)
                    : isPicked && _answered
                        ? scheme.primaryContainer
                        : null,
                side: isCorrect
                    ? const BorderSide(color: Colors.green, width: 2)
                    : null,
              ),
              onPressed:
                  (_answered || _revealed) ? null : () => _onAnswer(i),
              child: Text(q.options[i]),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (_answered && !_revealed) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_selected == q.correctIndex)
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selected == q.correctIndex ? S.correct : S.incorrect,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: (_selected == q.correctIndex)
                        ? Colors.green[800]
                        : Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.answersHiddenNote,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
        if (_revealed && !_answered)
          Text(
            S.timeUp,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16),
          ),
        if (_revealed)
          Text(
            '${S.correctAnswer}: ${q.options[q.correctIndex]}',
            style: TextStyle(
                color: Colors.green[800], fontWeight: FontWeight.w700),
          ),
      ],
    );
  }

  Widget _scoreScreen(ColorScheme scheme) {
    final total = widget.quiz.length;
    final pct = total == 0 ? 0 : (_score / total * 100).round();
    final msg = pct >= 80
        ? 'Excellent work!'
        : pct >= 50
            ? 'Good effort — keep practicing!'
            : 'Keep practicing, you\u2019ll get it!';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                size: 72, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(S.quizScore,
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '$_score / $total',
              style: const TextStyle(
                  fontSize: 44, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(S.ok),
            ),
          ],
        ),
      ),
    );
  }
}
