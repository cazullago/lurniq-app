import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/notify_service.dart';
import '../../store/app_store.dart';
import '../../widgets/tappable_name.dart';
import '../../widgets/ui.dart';
import 'course_form_screen.dart';

/// Course detail: description, lesson list, enroll + progress for students,
/// and create/edit/publish controls for the owning tutor.
class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  Future<void> _openVideo(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme.isEmpty) {
      showSnack(context, 'That video link doesn\u2019t look valid.');
      return;
    }
    final ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showSnack(context, 'Couldn\u2019t open the video link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final course = store.courseById(courseId);
    if (course == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.school_outlined,
          title: S.somethingWrong,
        ),
      );
    }
    final me = store.currentUser;
    final isOwner = me != null && me.id == course.tutorId;
    final enrolled = store.isEnrolled(courseId);
    final lessons = store.lessonsFor(courseId);
    final enrollment = store.enrollmentFor(courseId);
    final progress = store.courseProgress(courseId);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        actions: [
          if (course.isDemo) const DemoChip(),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: S.editCourse,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CourseFormScreen(courseId: course.id),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (course.thumbnailPath != null &&
              course.thumbnailPath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.file(
                File(course.thumbnailPath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                TappableName(
                  userId: course.tutorId,
                  name: course.tutorName,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (course.subject.isNotEmpty)
                      Chip(label: Text(course.subject)),
                    if (course.level.isNotEmpty)
                      Chip(label: Text(course.level)),
                    PriceTag(priceUsd: course.priceUsd),
                    if (!course.published && isOwner)
                      const Chip(
                        avatar: Icon(Icons.edit_rounded, size: 16),
                        label: Text(S.draft),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StarsRow(rating: course.rating),
                    const SizedBox(width: 6),
                    Text(
                      '${course.reviewCount} ${S.reviewsCount} · '
                      '${course.enrollmentCount} enrolled',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(course.description),
                if (course.priceUsd > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Demo mode: payment isn\u2019t collected for paid '
                    'courses yet (payments arrive in Phase 4).',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            color: scheme.onSurfaceVariant),
                  ),
                ],
                if (isOwner) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await store.setCoursePublished(
                                course.id, !course.published);
                            if (context.mounted) {
                              showSnack(
                                context,
                                course.published
                                    ? S.published
                                    : S.draft,
                              );
                            }
                          },
                          icon: Icon(course.published
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          label: Text(course.published
                              ? S.unpublish
                              : S.publish),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                          ),
                          onPressed: () async {
                            final ok = await confirmDialog(
                              context,
                              title: S.delete,
                              body:
                                  'Delete \u201c${course.title}\u201d and all its lessons?',
                            );
                            if (ok && context.mounted) {
                              await store.deleteCourse(course.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          },
                          icon:
                              const Icon(Icons.delete_outline_rounded),
                          label: const Text(S.delete),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (enrolled) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lessons.where((l) => enrollment?.doneLessonIds.contains(l.id) ?? false).length} of ${lessons.length} lessons done',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            color: scheme.onSurfaceVariant),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await store.enrollInCourse(courseId);
                        await NotifyService.instance.notifyNow(
                          title: S.courseEnrollTitle,
                          body:
                              'You enrolled in \u201c${course.title}\u201d.',
                        );
                        if (context.mounted) {
                          showSnack(context, S.courseEnrolledMsg);
                        }
                      },
                      child: Text(
                          '${S.enroll}${course.priceUsd > 0 ? ' · \$${course.priceUsd.toStringAsFixed(course.priceUsd.truncateToDouble() == course.priceUsd ? 0 : 2)}' : ''}'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Lessons (${lessons.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('No lessons yet.'),
            ),
          ...lessons.map((l) {
            final done =
                enrollment?.doneLessonIds.contains(l.id) ?? false;
            return _LessonTile(
              lesson: l,
              done: done,
              enrolled: enrolled,
              onTap: () {
                if (l.kind == 'video' && l.videoUrl.isNotEmpty) {
                  _openVideo(context, l.videoUrl);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _LessonReaderScreen(lesson: l),
                    ),
                  );
                }
              },
              onMarkDone: () =>
                  store.markLessonDone(courseId, l.id),
            );
          }),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.done,
    required this.enrolled,
    required this.onTap,
    required this.onMarkDone,
  });

  final CourseLesson lesson;
  final bool done;
  final bool enrolled;
  final VoidCallback onTap;
  final VoidCallback onMarkDone;

  IconData get _icon {
    switch (lesson.kind) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'slides':
        return Icons.view_carousel_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: done
                      ? Colors.green.withValues(alpha: 0.15)
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  done ? Icons.check_rounded : _icon,
                  color:
                      done ? Colors.green[700] : scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lesson.kind == 'video' ? S.lessonVideo : S.lessonSlides}'
                      '${lesson.durationMin > 0 ? ' · ${lesson.durationMin} ${S.minutes}' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (enrolled && !done)
                FilledButton.tonal(
                  onPressed: onMarkDone,
                  child: const Text(S.lessonDone),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-app reader for slides/text lessons.
class _LessonReaderScreen extends StatelessWidget {
  const _LessonReaderScreen({required this.lesson});

  final CourseLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          lesson.body.isEmpty ? 'No content yet.' : lesson.body,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
      ),
    );
  }
}
