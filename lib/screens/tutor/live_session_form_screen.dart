import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/options.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import '../legal/legal_screens.dart';
import 'quiz_builder.dart';

/// Tutor form to schedule a public live session: title, subject,
/// description, date/time, duration, meeting link, and a quiz builder.
class LiveSessionFormScreen extends StatefulWidget {
  const LiveSessionFormScreen({super.key});

  @override
  State<LiveSessionFormScreen> createState() =>
      _LiveSessionFormScreenState();
}

class _LiveSessionFormScreenState extends State<LiveSessionFormScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _link = TextEditingController();
  String _subject = '';
  DateTime? _date;
  TimeOfDay? _time;
  int _durationMin = 60;
  List<QuizQuestion> _quiz = [];
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty) {
      showSnack(context, 'Give your session a title.');
      return;
    }
    if (_date == null || _time == null) {
      showSnack(context, 'Please pick a date and a time first.');
      return;
    }
    if (_quiz.isNotEmpty && !QuizBuilder.validate(_quiz)) {
      showSnack(context,
          'Fix the quiz first: every question needs text, 2+ options, and one marked correct answer.');
      return;
    }
    final store = context.read<AppStore>();
    final me = store.currentUser;
    if (me == null) {
      showSnack(context, 'Please sign in first.');
      return;
    }
    setState(() => _saving = true);
    if (!await ensureTutorAgreement(context)) {
      setState(() => _saving = false);
      return;
    }
    final local = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    await store.createLiveSession(LiveSession(
      id: newId(),
      tutorId: me.id,
      tutorName: me.displayName,
      title: _title.text.trim(),
      subject: _subject,
      description: _description.text.trim(),
      startsAtUtc: local.toUtc(),
      durationMin: _durationMin,
      meetingLink: _link.text.trim(),
      status: 'scheduled',
      quiz: _quiz,
    ));
    if (mounted) {
      showSnack(context, 'Live session scheduled.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.scheduleLive),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '…' : S.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(labelText: S.liveTitle),
          ),
          const SizedBox(height: 12),
          OptionField(
            label: S.tutorSubject,
            value: _subject,
            title: S.tutorSubject,
            options: OptionLists.subjects,
            onChanged: (v) => setState(() => _subject = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(labelText: S.courseDescription),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(
                _date == null ? S.bookingDateTime : fmtDate(_date!)),
            trailing: const Icon(Icons.edit_rounded),
            onTap: _pickDate,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _date == null
                    ? scheme.error
                    : scheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(_time == null
                ? 'Pick a time *'
                : _time!.format(context)),
            trailing: const Icon(Icons.edit_rounded),
            onTap: _pickTime,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _time == null
                    ? scheme.error
                    : scheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LurniqDropdown<int>(
            label: S.bookingDuration,
            value: _durationMin,
            items: const [30, 45, 60, 90, 120]
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text('$m ${S.minutes}'),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _durationMin = v ?? 60),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _link,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: S.meetingLink,
              hintText: S.meetingLinkHint,
              prefixIcon: Icon(Icons.videocam_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            S.liveQuiz,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional: viewers answer these live, with a countdown per question.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          QuizBuilder(
            questions: const [],
            onChanged: (qs) => setState(() => _quiz = qs),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '…' : S.save),
          ),
        ],
      ),
    );
  }
}
