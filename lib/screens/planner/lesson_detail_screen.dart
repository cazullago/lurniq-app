import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'ai_sheet.dart';

/// Lesson detail: original photo (full view), notes, tags, edit/delete.
class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final lesson = store.lessons
        .where((l) => l.id == lessonId)
        .firstOrNull;
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.photo_library_outlined,
          title: S.somethingWrong,
        ),
      );
    }
    final folder = store.folderById(lesson.folderId);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: S.askAi,
            onPressed: () => AiSheet.show(
              context,
              title: S.askAi,
              contextText:
                  'Lesson: ${lesson.title}. Notes: ${lesson.notes}. Tags: ${lesson.tags.join(', ')}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: S.editLesson,
            onPressed: () => _edit(context, store, lesson.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: S.deleteLesson,
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: S.deleteLesson,
                body: S.deleteLessonConfirm,
              );
              if (ok) {
                await store.deleteLesson(lesson.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      _FullPhoto(path: lesson.photoPath)),
            ),
            child: Hero(
              tag: lesson.id,
              child: Image.file(
                File(lesson.photoPath),
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 1400,
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: scheme.surfaceContainerHighest,
                  child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 48),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fmtDate(lesson.lessonDate)}${folder != null ? ' · ${folder.name}' : ''}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: scheme.onSurfaceVariant),
                ),
                if (lesson.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    S.lessonNotes,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(lesson.notes,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge),
                ],
                if (lesson.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TagChips(tags: lesson.tags),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _edit(
      BuildContext context, AppStore store, String id) {
    final lesson =
        store.lessons.where((l) => l.id == id).firstOrNull;
    if (lesson == null) return;
    final title = TextEditingController(text: lesson.title);
    final notes = TextEditingController(text: lesson.notes);
    final tags = TextEditingController(
        text: lesson.tags.join(', '));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.editLesson),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(
                      labelText: S.lessonTitle)),
              const SizedBox(height: 12),
              TextField(
                  controller: notes,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                      labelText: S.lessonNotes,
                      alignLabelWithHint: true)),
              const SizedBox(height: 12),
              TextField(
                  controller: tags,
                  decoration: const InputDecoration(
                      labelText: S.topicTags,
                      hintText: S.topicTagsHint)),
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
              lesson.title = title.text.trim().isEmpty
                  ? lesson.title
                  : title.text.trim();
              lesson.notes = notes.text.trim();
              lesson.tags = tags.text
                  .split(',')
                  .map((t) => t
                      .trim()
                      .toLowerCase()
                      .replaceAll(RegExp(r'\s+'), '-'))
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .toList();
              await store.updateLesson(lesson);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(S.save),
          ),
        ],
      ),
    );
  }
}

class _FullPhoto extends StatelessWidget {
  const _FullPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.viewPhoto)),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}
