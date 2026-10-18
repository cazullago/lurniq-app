import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'ai_sheet.dart';
import 'task_form_screen.dart';

/// Task detail: full info, mark done / reopen, grade logging, Ask AI.
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final task = store.taskById(taskId);
    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.checklist_rounded,
          title: S.somethingWrong,
        ),
      );
    }
    final folder =
        task.folderId == null ? null : store.folderById(task.folderId!);
    final scheme = Theme.of(context).colorScheme;
    final isDone = task.isDone;
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.taskTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit task',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => TaskFormScreen(taskId: task.id)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(task.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                  icon: Icons.category_outlined,
                  label: task.typeLabel.isEmpty
                      ? S.notSet
                      : _cap(task.typeLabel)),
              if (folder != null)
                _Chip(icon: Icons.folder_outlined, label: folder.name),
              _Chip(
                  icon: Icons.flag_outlined,
                  label: _cap(task.priority),
                  highlight: task.priority == 'high' && !isDone),
              if (task.dueAtLocal != null)
                _Chip(
                    icon: Icons.schedule_outlined,
                    label: fmtDateTime(task.dueAtLocal!),
                    highlight: task.isOverdue),
              _Chip(
                icon: isDone
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                label: isDone ? S.statusDone : S.statusTodo,
              ),
              if (isDone && task.completedAt != null)
                _Chip(
                    icon: Icons.event_available_outlined,
                    label:
                        '${S.completed}: ${fmtDate(task.completedAt!)}'),
            ],
          ),
          if (task.instructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(S.taskInstructions,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(task.instructions,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (task.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(S.taskNotes,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(task.notes,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (task.photoPath != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(task.photoPath!),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  color: scheme.surfaceContainerHighest,
                  child: const Icon(
                      Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ],
          if (task.gradeScore.isNotEmpty) ...[
            const SizedBox(height: 16),
            _GradeCard(task: task),
          ],
          const SizedBox(height: 24),
          if (!isDone)
            FilledButton.icon(
              onPressed: () async {
                await store.completeTask(task.id);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text(S.markDone),
            )
          else ...[
            FilledButton.icon(
              onPressed: () async {
                await store.reopenTask(task.id);
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text(S.reopenTask),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _logGradeSheet(context, task),
              icon: const Icon(Icons.grade_outlined),
              label: const Text(S.logGrade),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => AiSheet.show(
              context,
              title: S.askAi,
              contextText:
                  'Task: ${task.title} (${task.typeLabel}). Instructions: ${task.instructions}. Notes: ${task.notes}',
            ),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text(S.askAi),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Grade logging bottom sheet: score text field, note, optional photo.
  Future<void> _logGradeSheet(BuildContext context, StudyTask task) async {
    final score = TextEditingController(text: task.gradeScore);
    final note = TextEditingController(text: task.gradeNote);
    String? photoPath = task.gradePhotoPath;
    final store = context.read<AppStore>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(S.logGrade,
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: score,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: S.logGrade,
                      hintText: S.gradeScoreHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: S.logGrade,
                      hintText: S.gradeNoteHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(
                        Icons.add_photo_alternate_outlined),
                    label: Text(photoPath == null
                        ? S.gradePhotoHint
                        : S.viewPhoto),
                    onPressed: () async {
                      final path = await pickAndSaveImage(
                          ctx, store.appDir,
                          camera: false);
                      if (path != null) {
                        if (photoPath != null) {
                          deleteImageQuietly(photoPath);
                        }
                        setSheetState(() => photoPath = path);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final s = score.text.trim();
                      if (s.isEmpty) {
                        showSnack(ctx, S.gradeScoreHint);
                        return;
                      }
                      await store.saveGrade(task.id,
                          score: s,
                          note: note.text,
                          photoPath: photoPath);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text(S.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    score.dispose();
    note.dispose();
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.icon, required this.label, this.highlight = false});

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15,
              color: highlight
                  ? scheme.onErrorContainer
                  : scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlight
                    ? scheme.onErrorContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Performance-record grade card on a done task.
class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.task});

  final StudyTask task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grade_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Text(task.gradeScore,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          if (task.gradeNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(task.gradeNote,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (task.gradePhotoPath != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(task.gradePhotoPath!),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
