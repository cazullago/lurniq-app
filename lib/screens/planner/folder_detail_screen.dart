import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'capture_lesson_screen.dart';
import 'planner_tab.dart' show LessonRow;

/// Lessons inside one subject folder.
class FolderDetailScreen extends StatelessWidget {
  const FolderDetailScreen({super.key, required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final folder = store.folderById(folderId);
    if (folder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.folder_outlined,
          title: S.somethingWrong,
        ),
      );
    }
    final lessons = store.lessonsIn(folderId);
    final color = Color(folder.colorValue);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(folderIconFor(folder.icon), color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(folder.name)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  CaptureLessonScreen(folderId: folderId)),
        ),
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text(S.captureLesson),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(S.ocrPhase2,
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          Expanded(
            child: lessons.isEmpty
                ? EmptyState(
                    icon: Icons.photo_library_outlined,
                    title: S.noLessons,
                    subtitle: S.noLessonsHint,
                    actionLabel: S.captureLesson,
                    onAction: () =>
                        Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              CaptureLessonScreen(
                                  folderId: folderId)),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: lessons.length,
                    itemBuilder: (context, i) =>
                        LessonRow(lesson: lessons[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
