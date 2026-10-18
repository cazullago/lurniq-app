import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';

/// Inline quiz editor: add/remove questions; per question a text field,
/// 2–4 options, a radio marking the one correct answer, and seconds per
/// question. Emits the edited [QuizQuestion] list through [onChanged].
/// Inline validation notes appear under each question card.
class QuizBuilder extends StatefulWidget {
  const QuizBuilder({
    super.key,
    required this.questions,
    required this.onChanged,
  });

  final List<QuizQuestion> questions;
  final ValueChanged<List<QuizQuestion>> onChanged;

  /// Save-time check: every question has text, ≥2 filled options, and a
  /// valid correct index.
  static bool validate(List<QuizQuestion> qs) {
    if (qs.isEmpty) return false;
    for (final q in qs) {
      final opts =
          q.options.where((o) => o.trim().isNotEmpty).toList();
      if (q.question.trim().isEmpty) return false;
      if (opts.length < 2) return false;
      if (q.correctIndex < 0 || q.correctIndex >= opts.length) {
        return false;
      }
    }
    return true;
  }

  @override
  State<QuizBuilder> createState() => _QuizBuilderState();
}

class _DraftQ {
  _DraftQ({QuizQuestion? from}) {
    if (from != null) {
      question.text = from.question;
      seconds.text = from.secondsPerQuestion.toString();
      final opts = from.options.toList();
      while (opts.length < 2) {
        opts.add('');
      }
      for (final o in opts.take(4)) {
        options.add(TextEditingController(text: o));
      }
      correct = from.correctIndex.clamp(0, options.length - 1);
    } else {
      seconds.text = '30';
      options.addAll(
          [TextEditingController(), TextEditingController()]);
    }
  }

  final TextEditingController question = TextEditingController();
  final List<TextEditingController> options = [];
  final TextEditingController seconds = TextEditingController();
  int correct = 0;

  QuizQuestion toQuestion() {
    final opts =
        options.map((c) => c.text.trim()).where((o) => o.isNotEmpty).toList();
    return QuizQuestion(
      id: newId(),
      question: question.text.trim(),
      options: opts,
      correctIndex:
          opts.isEmpty ? 0 : correct.clamp(0, opts.length - 1),
      secondsPerQuestion:
          int.tryParse(seconds.text.trim())?.clamp(5, 300) ?? 30,
    );
  }

  List<String> errors() {
    final errs = <String>[];
    if (question.text.trim().isEmpty) errs.add('Add a question.');
    final filled = options
        .where((c) => c.text.trim().isNotEmpty)
        .length;
    if (filled < 2) errs.add('Add at least 2 options.');
    return errs;
  }

  void dispose() {
    question.dispose();
    seconds.dispose();
    for (final c in options) {
      c.dispose();
    }
  }
}

class _QuizBuilderState extends State<QuizBuilder> {
  final List<_DraftQ> _drafts = [];

  @override
  void initState() {
    super.initState();
    for (final q in widget.questions) {
      _drafts.add(_DraftQ(from: q));
    }
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_drafts.map((d) => d.toQuestion()).toList());
  }

  void _addQuestion() {
    setState(() => _drafts.add(_DraftQ()));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_drafts.length, (qi) {
          final d = _drafts[qi];
          final errs = d.errors();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${S.questionHint} ${qi + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.delete_outline_rounded),
                        tooltip: S.delete,
                        onPressed: () {
                          setState(() {
                            d.dispose();
                            _drafts.removeAt(qi);
                          });
                          _emit();
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: d.question,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        hintText: S.questionHint),
                    onChanged: (_) => _emit(),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(d.options.length, (oi) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 6),
                      child: RadioGroup<int>(
                        groupValue: d.correct,
                        onChanged: (v) {
                          setState(() => d.correct = v ?? 0);
                          _emit();
                        },
                        child: Row(
                          children: [
                            Radio<int>(value: oi),
                            Expanded(
                              child: TextField(
                              controller: d.options[oi],
                              decoration: InputDecoration(
                                hintText: '${S.optionHint} ${oi + 1}',
                                suffixIcon: d.options.length > 2
                                    ? IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            d.options[oi].dispose();
                                            d.options.removeAt(oi);
                                            d.correct = d.correct.clamp(
                                                0, d.options.length - 1);
                                          });
                                          _emit();
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (_) => _emit(),
                            ),
                          ),
                        ],
                        ),
                      ),
                    );
                  }),
                  if (d.options.length < 4)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => d.options
                            .add(TextEditingController()));
                        _emit();
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('${S.optionHint} ${d.options.length + 1}'),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.correctAnswer,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: d.seconds,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            labelText: S.timerSeconds,
                          ),
                          onChanged: (_) => _emit(),
                        ),
                      ),
                    ],
                  ),
                  if (errs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...errs.map((e) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 2),
                          child: Text(
                            e,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: _addQuestion,
          icon: const Icon(Icons.add_rounded),
          label: const Text(S.addQuestion),
        ),
      ],
    );
  }
}
