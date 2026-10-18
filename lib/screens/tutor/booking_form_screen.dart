import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../services/notify_service.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';

/// 1v1 booking request form: date + time pickers (both REQUIRED),
/// duration dropdown, meeting link and note fields. The start time is
/// stored in UTC; on-device reminder scheduling is demo-only and honest.
class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({
    super.key,
    required this.tutorId,
    required this.tutorName,
  });

  final String tutorId;
  final String tutorName;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  int _durationMin = 60;
  final _link = TextEditingController();
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _link.dispose();
    _note.dispose();
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

  Future<void> _send() async {
    if (_sending) return;
    if (_date == null || _time == null) {
      showSnack(context, 'Please pick a date and a time first.');
      return;
    }
    final store = context.read<AppStore>();
    final me = store.currentUser;
    if (me == null) {
      showSnack(context, 'Please sign in first.');
      return;
    }
    setState(() => _sending = true);
    final local = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    await store.requestBooking(
      tutorId: widget.tutorId,
      tutorName: widget.tutorName,
      startsAtUtc: local.toUtc(),
      durationMin: _durationMin,
      meetingLink: _link.text.trim(),
      note: _note.text.trim(),
    );
    await NotifyService.instance.notifyNow(
      title: S.bookingRequestTitle,
      body:
          '${me.displayName} requested a 1v1 session with ${widget.tutorName}.',
    );
    if (mounted) {
      showSnack(context, S.bookingSent);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(S.bookSession)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  widget.tutorName.isEmpty
                      ? '?'
                      : widget.tutorName[0].toUpperCase(),
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(widget.tutorName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700)),
              subtitle: const Text(
                  'Demo mode: the tutor\u2019s accept/decline response is simulated on this device.'),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(_date == null
                ? S.bookingDateTime
                : fmtDate(_date!)),
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
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: S.bookingNoteHint,
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? '…' : S.sendRequest),
          ),
        ],
      ),
    );
  }
}
