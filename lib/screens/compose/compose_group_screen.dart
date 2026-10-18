import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'preview_screen.dart';

/// Study-group invitation composer. The event time is stored in UTC and each
/// participant sees it in their own timezone.
class ComposeGroupScreen extends StatefulWidget {
  const ComposeGroupScreen({super.key});

  @override
  State<ComposeGroupScreen> createState() => _ComposeGroupScreenState();
}

class _ComposeGroupScreenState extends State<ComposeGroupScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _link = TextEditingController();
  final _location = TextEditingController();
  String? _subject;
  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 60;
  int _max = 8;
  String _format = 'online';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _link.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Post? _draft(AppStore store) {
    if (_title.text.trim().isEmpty ||
        _desc.text.trim().isEmpty ||
        _date == null ||
        _time == null) {
      return null;
    }
    final me = store.currentUser!;
    final wall =
        DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    return Post(
      id: newId(),
      authorId: me.id,
      authorName: me.displayName,
      authorAvatar: me.avatarPath,
      type: 'studyGroup',
      title: _title.text.trim(),
      body: _desc.text.trim(),
      subject: _subject ?? '',
      groupStartsAtUtc: viewerWallToUtc(wall, me),
      groupDurationMin: _duration,
      groupMaxParticipants: _max,
      groupFormat: _format,
      groupLink: _format == 'online' ? _link.text.trim() : null,
      groupLocation: _format == 'inPerson' ? _location.text.trim() : null,
      participantIds: [me.id],
    );
  }

  void _preview() {
    final store = context.read<AppStore>();
    final draft = _draft(store);
    if (draft == null) {
      showSnack(context, S.bodyRequired);
      return;
    }
    final me = store.currentUser!;
    final local = utcToViewer(draft.groupStartsAtUtc!, me);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          post: draft,
          publishLabel: S.publishInvitation,
          onPublish: _publish,
          extra: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              Text('${S.groupDate}: ${fmtDateTime(local)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                  '${_format == 'online' ? S.groupOnline : S.groupInPerson} · $_duration min · max $_max'),
              Text(S.groupTimezoneNote,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publish() async {
    final store = context.read<AppStore>();
    final draft = _draft(store);
    if (draft == null) return;
    setState(() => _busy = true);
    try {
      await store.createPost(draft);
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        showSnack(context, S.invitationPublished);
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
      appBar: AppBar(
        title: const Text(S.optionStudyGroup),
        actions: [
          TextButton(
            onPressed: _preview,
            child: const Text(S.preview),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.groupTitle,
              ),
            ),
            const SizedBox(height: 12),
            LurniqDropdown<String>(
              label: S.groupSubject,
              value: _subject,
              items: stringMenuItems(C.subjects),
              onChanged: (v) => setState(() => _subject = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.groupDescription,
                hintText: S.groupDescriptionHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(S.groupDate,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_date == null
                        ? S.groupDate
                        : fmtDate(_date!)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(_time == null
                        ? S.groupTime
                        : _time!.format(context)),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(S.groupTimezoneNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.groupDuration,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700)),
                      DropdownButtonFormField<int>(
                        initialValue: _duration,
                        items: [30, 45, 60, 90, 120, 180]
                            .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('$d min')))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _duration = v ?? 60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.groupMax,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700)),
                      DropdownButtonFormField<int>(
                        initialValue: _max,
                        items: [2, 4, 6, 8, 12, 20, 50]
                            .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('$d')))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _max = v ?? 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(S.groupFormat,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'online',
                    icon: Icon(Icons.videocam_outlined),
                    label: Text(S.groupOnline)),
                ButtonSegment(
                    value: 'inPerson',
                    icon: Icon(Icons.place_outlined),
                    label: Text(S.groupInPerson)),
              ],
              selected: {_format},
              onSelectionChanged: (s) =>
                  setState(() => _format = s.first),
            ),
            const SizedBox(height: 12),
            if (_format == 'online')
              TextField(
                controller: _link,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: S.groupLink,
                  hintText: 'https://…',
                ),
              )
            else ...[
              TextField(
                controller: _location,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: S.groupLocation,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 20,
                        color: scheme.onErrorContainer),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(S.groupLocationSafety,
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _preview,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(S.preview),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
