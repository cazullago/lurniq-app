import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/options.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../legal/legal_screens.dart';

/// Create/edit a course: title, description, subject, level, price,
/// thumbnail (image_picker) and a lesson editor (add/edit/delete lessons
/// with kind video|slides|text). New courses start as drafts — the tutor
/// publishes them from the course detail screen.
class CourseFormScreen extends StatefulWidget {
  const CourseFormScreen({super.key, this.courseId});

  final String? courseId;

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _LessonDraft {
  _LessonDraft({CourseLesson? from}) {
    if (from != null) {
      id = from.id;
      title.text = from.title;
      kind = from.kind;
      videoUrl.text = from.videoUrl;
      body.text = from.body;
      duration.text = from.durationMin.toString();
      order = from.order;
    } else {
      id = newId();
    }
  }

  String id = newId();
  final TextEditingController title = TextEditingController();
  String kind = 'slides'; // video | slides (text uses 'slides' reader too)
  final TextEditingController videoUrl = TextEditingController();
  final TextEditingController body = TextEditingController();
  final TextEditingController duration = TextEditingController();
  int order = 0;

  CourseLesson toLesson(String courseId, int order) => CourseLesson(
        id: id,
        courseId: courseId,
        title: title.text.trim(),
        kind: kind,
        videoUrl: videoUrl.text.trim(),
        body: body.text.trim(),
        durationMin: int.tryParse(duration.text.trim()) ?? 0,
        order: order,
      );

  void dispose() {
    title.dispose();
    videoUrl.dispose();
    body.dispose();
    duration.dispose();
  }
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _subject = '';
  String _level = '';
  String? _thumbnailPath;
  final List<_LessonDraft> _lessons = [];
  bool _saving = false;
  late final AppStore _store;
  Course? _existing;

  @override
  void initState() {
    super.initState();
    _store = context.read<AppStore>();
    if (widget.courseId != null) {
      _existing = _store.courseById(widget.courseId!);
      final c = _existing;
      if (c != null) {
        _title.text = c.title;
        _description.text = c.description;
        _price.text = c.priceUsd == 0
            ? ''
            : (c.priceUsd.truncateToDouble() == c.priceUsd
                ? c.priceUsd.toInt().toString()
                : c.priceUsd.toString());
        _subject = c.subject;
        _level = c.level;
        _thumbnailPath = c.thumbnailPath;
        for (final l in _store.lessonsFor(c.id)) {
          _lessons.add(_LessonDraft(from: l));
        }
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    for (final l in _lessons) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final path = await pickAndSaveImage(
      context,
      _store.appDir,
      camera: false,
    );
    if (path != null && mounted) {
      setState(() => _thumbnailPath = path);
    }
  }

  void _addLesson() {
    setState(() => _lessons.add(_LessonDraft()));
  }

  void _editLesson(_LessonDraft draft) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LessonEditorSheet(draft: draft),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty) {
      showSnack(context, 'Give your course a title.');
      return;
    }
    if (_lessons.any((l) => l.title.text.trim().isEmpty)) {
      showSnack(context, 'Every lesson needs a title.');
      return;
    }
    final me = _store.currentUser;
    if (me == null) {
      showSnack(context, 'Please sign in first.');
      return;
    }
    setState(() => _saving = true);
    final price = double.tryParse(_price.text.trim()) ?? 0;
    final id = widget.courseId ?? newId();
    final existing = _existing;
    final course = Course(
      id: id,
      tutorId: me.id,
      tutorName: me.displayName,
      title: _title.text.trim(),
      description: _description.text.trim(),
      subject: _subject,
      level: _level,
      thumbnailPath: _thumbnailPath,
      priceUsd: price < 0 ? 0 : price,
      published: existing?.published ?? false,
      rating: existing?.rating ?? 0,
      reviewCount: existing?.reviewCount ?? 0,
      enrollmentCount: existing?.enrollmentCount ?? 0,
      isDemo: false,
    );
    if (existing == null) {
      if (!await ensureTutorAgreement(context)) {
        setState(() => _saving = false);
        return;
      }
      await _store.createCourse(course);
    } else {
      await _store.updateCourse(course);
    }
    final keepIds = _lessons.map((l) => l.id).toSet();
    for (final old
        in _store.lessonsFor(id).where((l) => !keepIds.contains(l.id))) {
      await _store.deleteCourseLesson(old.id);
    }
    for (var i = 0; i < _lessons.length; i++) {
      await _store.saveCourseLesson(_lessons[i].toLesson(id, i));
    }
    if (mounted) {
      showSnack(context, 'Course saved.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.courseId == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? S.createCourse : S.editCourse),
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
          if (_existing?.isDemo != true && !isNew)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiaryContainer
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _existing!.published
                    ? 'This course is published and visible to everyone.'
                    : 'This course is a draft. Publish it from the course page when it\u2019s ready.',
              ),
            ),
          GestureDetector(
            onTap: _pickThumbnail,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _thumbnailPath != null && _thumbnailPath!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_thumbnailPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const Positioned(
                          right: 8,
                          bottom: 8,
                          child: CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.edit_rounded, size: 18),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 36),
                          SizedBox(height: 6),
                          Text('Add a thumbnail'),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: S.courseTitle),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(labelText: S.courseDescription),
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
          OptionField(
            label: S.tutorLevel,
            value: _level,
            title: S.tutorLevel,
            options: OptionLists.educationLevels,
            onChanged: (v) => setState(() => _level = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Price (USD, 0 = free)',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lessons (${_lessons.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addLesson,
                icon: const Icon(Icons.add_rounded),
                label: const Text(S.addLesson),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_lessons.length, (i) {
            final d = _lessons[i];
            return Card(
              child: ListTile(
                leading: Icon(
                  d.kind == 'video'
                      ? Icons.play_circle_outline_rounded
                      : Icons.article_outlined,
                ),
                title: Text(d.title.text.trim().isEmpty
                    ? '${S.lessonTitle} ${i + 1}'
                    : d.title.text.trim()),
                subtitle: Text(d.kind == 'video'
                    ? S.lessonVideo
                    : S.lessonSlides),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.delete_outline_rounded),
                  onPressed: () => setState(() {
                    d.dispose();
                    _lessons.removeAt(i);
                  }),
                ),
                onTap: () => _editLesson(d),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '…' : S.save),
          ),
        ],
      ),
    );
  }
}

class _LessonEditorSheet extends StatefulWidget {
  const _LessonEditorSheet({required this.draft});

  final _LessonDraft draft;

  @override
  State<_LessonEditorSheet> createState() => _LessonEditorSheetState();
}

class _LessonEditorSheetState extends State<_LessonEditorSheet> {
  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.addLesson,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: d.title,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(labelText: S.lessonTitle),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(S.lessonKind,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'video', label: Text(S.lessonVideo)),
                ButtonSegment(
                    value: 'slides', label: Text(S.lessonSlides)),
              ],
              selected: {d.kind == 'video' ? 'video' : 'slides'},
              onSelectionChanged: (s) =>
                  setState(() => d.kind = s.first),
            ),
            const SizedBox(height: 12),
            if (d.kind == 'video')
              TextField(
                controller: d.videoUrl,
                keyboardType: TextInputType.url,
                decoration:
                    const InputDecoration(hintText: S.videoUrlHint),
              )
            else
              TextField(
                controller: d.body,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    const InputDecoration(hintText: S.lessonBodyHint),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: d.duration,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(S.saveLesson),
            ),
          ],
        ),
      ),
    );
  }
}
