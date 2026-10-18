import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';

/// Create / edit a study task. The optional photo attachment is stored now;
/// reading assignment details from photos arrives in Phase 2 (never faked).
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  final _notes = TextEditingController();
  String? _folderId;
  DateTime? _date;
  TimeOfDay? _time;
  String _priority = 'medium';
  String _status = 'todo';
  bool _reminder = false;
  String? _photoPath;
  bool _busy = false;
  bool _loaded = false;

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _loadIfNeeded(AppStore store) {
    if (_loaded || widget.taskId == null) return;
    final task =
        store.tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task != null) {
      _title.text = task.title;
      _instructions.text = task.instructions;
      _notes.text = task.notes;
      _folderId = task.folderId;
      _priority = task.priority;
      _status = task.status;
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
      due = DateTime(
          _date!.year, _date!.month, _date!.day, t.hour, t.minute);
    }
    setState(() => _busy = true);
    try {
      final store = context.read<AppStore>();
      if (widget.taskId == null) {
        await store.addTask(
          title: _title.text,
          folderId: _folderId,
          instructions: _instructions.text,
          dueAtLocal: due,
          priority: _priority,
          notes: _notes.text,
          photoPath: _photoPath,
          reminder: _reminder,
        );
        if (mounted) showSnack(context, S.taskSaved);
      } else {
        final task = store.tasks
            .where((t) => t.id == widget.taskId)
            .firstOrNull;
        if (task != null) {
          task.title = _title.text.trim().isEmpty
              ? task.title
              : _title.text.trim();
          task.folderId = _folderId;
          task.instructions = _instructions.text.trim();
          task.dueAtLocal = due;
          task.priority = _priority;
          task.notes = _notes.text.trim();
          task.photoPath = _photoPath;
          task.reminder = _reminder;
          if (_status != task.status) {
            store.setTaskStatus(task.id, _status);
          } else {
            await store.updateTask(task);
          }
          if (mounted) showSnack(context, S.taskSaved);
        }
      }
      if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    _loadIfNeeded(store);
    final folders = store.myFolders;
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.taskId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? S.taskTitle : S.newTask),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
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
                labelText: S.taskTitle,
                hintText: S.taskTitleHint,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LurniqDropdown<String>(
                    label: S.subject,
                    value: _folderId,
                    hint: S.all,
                    items: [
                      const DropdownMenuItem(
                          value: null,
                          child: Text(S.noDueDate)),
                      ...folders.map((f) =>
                          DropdownMenuItem(
                              value: f.id,
                              child: Text(f.name))),
                    ],
                    onChanged: (v) =>
                        setState(() => _folderId = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LurniqDropdown<String>(
                    label: S.priority,
                    value: _priority,
                    items: const [
                      DropdownMenuItem(
                          value: 'low',
                          child: Text(S.priorityLow)),
                      DropdownMenuItem(
                          value: 'medium',
                          child:
                              Text(S.priorityMedium)),
                      DropdownMenuItem(
                          value: 'high',
                          child: Text(S.priorityHigh)),
                    ],
                    onChanged: (v) => setState(
                        () => _priority = v ?? 'medium'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            Text(S.dueDate,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                        Icons.calendar_month_outlined),
                    label: Text(_date == null
                        ? S.noDueDate
                        : fmtDate(_date!)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                        Icons.schedule_outlined),
                    label: Text(_time == null
                        ? S.dueTime
                        : _time!.format(context)),
                    onPressed: _date == null
                        ? null
                        : _pickTime,
                  ),
                ),
                if (_date != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() {
                      _date = null;
                      _time = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: S.taskNotes,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(S.reminder),
              subtitle:
                  const Text(S.reminderPhase2Note),
              value: _reminder,
              onChanged: (v) =>
                  setState(() => _reminder = v),
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(
                  Icons.add_photo_alternate_outlined),
              label: Text(_photoPath == null
                  ? S.attachPhoto
                  : S.viewPhoto),
              onPressed: _attachPhoto,
            ),
            Text(S.taskFromPhotoPhase2,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        color: scheme.onSurfaceVariant)),
            if (isEdit) ...[
              const SizedBox(height: 12),
              LurniqDropdown<String>(
                label: S.status,
                value: _status,
                items: const [
                  DropdownMenuItem(
                      value: 'todo',
                      child: Text(S.statusTodo)),
                  DropdownMenuItem(
                      value: 'doing',
                      child: Text(S.statusDoing)),
                  DropdownMenuItem(
                      value: 'done',
                      child: Text(S.statusDone)),
                ],
                onChanged: (v) =>
                    setState(() => _status = v ?? 'todo'),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                                strokeWidth: 2),
                      )
                    : const Text(S.saveTask),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
