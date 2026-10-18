import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/options.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';

/// Create / edit a study task.
///
/// Scroll-safe redesign (the v1 form overflowed by ~50px on real phone
/// widths): everything scrolls in one column, all fields are full-width,
/// no side-by-side rows with fixed widths. The optional photo attachment
/// is stored now; reading assignment details from photos arrives in
/// Phase 2 (never faked).
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  static const _noSubject = 'No subject';

  final _title = TextEditingController();
  final _typeCustom = TextEditingController();
  final _instructions = TextEditingController();
  final _notes = TextEditingController();
  String? _folderId;
  String _taskType = 'assignment';
  String _priority = 'medium';
  DateTime? _date;
  TimeOfDay? _time;
  bool _reminder = false;
  String? _photoPath;
  bool _busy = false;
  bool _loaded = false;

  @override
  void dispose() {
    _title.dispose();
    _typeCustom.dispose();
    _instructions.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _loadIfNeeded(AppStore store) {
    if (_loaded || widget.taskId == null) return;
    final task = store.taskById(widget.taskId!);
    if (task != null) {
      _title.text = task.title;
      _taskType = task.taskType;
      _typeCustom.text = task.taskTypeCustom;
      _instructions.text = task.instructions;
      _notes.text = task.notes;
      _folderId = task.folderId;
      _priority = task.priority;
      _reminder = task.reminder;
      _photoPath = task.photoPath;
      final d = task.dueAtLocal;
      if (d != null) {
        _date = DateTime(d.year, d.month, d.day);
        _time = TimeOfDay(hour: d.hour, minute: d.minute);
      }
    }
    _loaded = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    // A time needs a date first — pick one on the fly instead of leaving
    // a dead disabled button.
    if (_date == null) {
      await _pickDate();
      if (_date == null || !mounted) return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _attachPhoto() async {
    final store = context.read<AppStore>();
    final path =
        await pickAndSaveImage(context, store.appDir, camera: false);
    if (path != null) {
      if (_photoPath != null) deleteImageQuietly(_photoPath);
      setState(() => _photoPath = path);
    }
  }

  Future<void> _save() async {
    DateTime? due;
    if (_date != null) {
      final t = _time ?? const TimeOfDay(hour: 23, minute: 59);
      due = DateTime(_date!.year, _date!.month, _date!.day, t.hour, t.minute);
    }
    setState(() => _busy = true);
    try {
      final store = context.read<AppStore>();
      final custom = _typeCustom.text.trim();
      final type =
          _taskType == 'other' && custom.isEmpty ? 'assignment' : _taskType;
      if (widget.taskId == null) {
        // addTask has no type parameters, so they are set on the returned
        // task and persisted with updateTask.
        final task = await store.addTask(
          title: _title.text,
          folderId: _folderId,
          instructions: _instructions.text,
          dueAtLocal: due,
          priority: _priority,
          notes: _notes.text,
          photoPath: _photoPath,
          reminder: _reminder,
        );
        task.taskType = type;
        task.taskTypeCustom = type == 'other' ? custom : '';
        await store.updateTask(task);
      } else {
        final task = store.taskById(widget.taskId!);
        if (task != null) {
          if (_title.text.trim().isNotEmpty) {
            task.title = _title.text.trim();
          }
          task.taskType = type;
          task.taskTypeCustom = type == 'other' ? custom : '';
          task.folderId = _folderId;
          task.instructions = _instructions.text.trim();
          task.dueAtLocal = due;
          task.priority = _priority;
          task.notes = _notes.text.trim();
          task.photoPath = _photoPath;
          task.reminder = _reminder;
          await store.updateTask(task);
        }
      }
      if (mounted) {
        showSnack(context, S.taskSaved);
        Navigator.of(context).pop();
      }
    } on StoreException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: S.deleteTask,
      body: S.deleteTaskConfirm,
    );
    if (!ok || widget.taskId == null) return;
    if (!mounted) return;
    await context.read<AppStore>().deleteTask(widget.taskId!);
    if (mounted) Navigator.of(context).pop();
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _typeLabel() {
    if (_taskType == 'other') {
      final custom = _typeCustom.text.trim();
      if (custom.isNotEmpty) return custom;
    }
    return _cap(_taskType);
  }

  void _onTypeChanged(String picked) {
    if (OptionLists.taskTypes.contains(picked)) {
      setState(() {
        _taskType = picked.toLowerCase();
        _typeCustom.clear();
      });
    } else {
      setState(() {
        _taskType = 'other';
        _typeCustom.text = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    _loadIfNeeded(store);
    final folders = store.myFolders;
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.taskId != null;
    final typeValue = _typeLabel();
    final subjectValue =
        _folderId == null ? '' : (store.folderById(_folderId!)?.name ?? '');
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? S.taskTitle : S.newTask),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: S.deleteTask,
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.taskTitle,
                hintText: S.taskTitleHint,
              ),
            ),
            const SizedBox(height: 14),
            OptionField(
              label: S.taskType,
              value: typeValue,
              title: S.taskTypeHint,
              options: OptionLists.taskTypes,
              icon: Icons.category_outlined,
              onChanged: _onTypeChanged,
            ),
            if (_taskType == 'other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _typeCustom,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: S.taskType,
                  hintText: S.taskTypeHint,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 14),
            OptionField(
              label: S.subject,
              value: subjectValue,
              title: S.subject,
              options: [_noSubject, ...folders.map((f) => f.name)],
              icon: Icons.folder_outlined,
              onChanged: (picked) {
                if (picked == _noSubject) {
                  setState(() => _folderId = null);
                  return;
                }
                final match =
                    folders.where((f) => f.name == picked).firstOrNull;
                setState(() => _folderId = match?.id);
              },
            ),
            const SizedBox(height: 14),
            OptionField(
              label: S.priority,
              value: _cap(_priority),
              title: S.priority,
              options: OptionLists.priorities,
              icon: Icons.flag_outlined,
              onChanged: (picked) =>
                  setState(() => _priority = picked.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Text(S.dueDate,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_date == null ? S.noDueDate : fmtDate(_date!)),
              onPressed: _pickDate,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule_outlined),
              label: Text(
                  _time == null ? S.dueTime : _time!.format(context)),
              onPressed: _pickTime,
            ),
            if (_date != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: Text(S.noDueDate,
                      style: const TextStyle(fontSize: 13)),
                  onPressed: () => setState(() {
                    _date = null;
                    _time = null;
                  }),
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _instructions,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.taskInstructions,
                hintText: S.taskInstructionsHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.taskNotes,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(S.reminder),
              subtitle: const Text(S.reminderPhase2Note),
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
            ),
            if (_photoPath != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_photoPath!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 80,
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(
                        Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_photoPath == null ? S.attachPhoto : S.viewPhoto),
              onPressed: _attachPhoto,
            ),
            Text(S.taskFromPhotoPhase2,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(S.saveTask),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
