import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';

/// Lesson capture: take/choose a photo, then file it with metadata.
/// OCR text extraction arrives in Phase 2 — nothing is faked here.
class CaptureLessonScreen extends StatefulWidget {
  const CaptureLessonScreen({super.key, required this.folderId});

  final String folderId;

  @override
  State<CaptureLessonScreen> createState() =>
      _CaptureLessonScreenState();
}

class _CaptureLessonScreenState
    extends State<CaptureLessonScreen> {
  String? _photoPath;
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _tags = TextEditingController();
  String? _folderId;
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _folderId = widget.folderId;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    final store = context.read<AppStore>();
    final path =
        await pickAndSaveImage(context, store.appDir, camera: camera);
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  List<String> get _tagList => _tags.text
      .split(',')
      .map((t) => t.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-'))
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _save() async {
    if (_photoPath == null) {
      showSnack(context, S.choosePhotoSource);
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AppStore>().addLesson(
            folderId: _folderId ?? widget.folderId,
            title: _title.text,
            photoPath: _photoPath!,
            notes: _notes.text,
            tags: _tagList,
            lessonDate: _date,
          );
      if (mounted) {
        Navigator.of(context).pop();
        showSnack(context, S.lessonSaved);
      }
    } on StoreException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final folders = store.myFolders;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(S.captureLesson)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                            Icons.photo_camera_outlined),
                        title:
                            const Text(S.takePhoto),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _pick(true);
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                            Icons.photo_library_outlined),
                        title: const Text(
                            S.chooseFromGallery),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _pick(false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _photoPath == null
                    ? Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                              Icons
                                  .add_photo_alternate_outlined,
                              size: 48,
                              color:
                                  scheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(S.choosePhotoSource,
                              style: TextStyle(
                                  color: scheme
                                      .onSurfaceVariant)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius:
                            BorderRadius.circular(16),
                        child: Image.file(
                          File(_photoPath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          cacheWidth: 1200,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            LurniqDropdown<String>(
              label: S.subject,
              value: _folderId,
              items: folders
                  .map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _folderId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.lessonTitle,
                hintText: S.lessonTitleHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.lessonNotes,
                hintText: S.lessonNotesHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tags,
                    decoration: const InputDecoration(
                      labelText: S.topicTags,
                      hintText: S.topicTagsHint,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                        Icons.calendar_month_outlined),
                    label: Text(fmtDate(_date)),
                    onPressed: _pickDate,
                  ),
                ),
              ],
            ),
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
                    : const Text(S.saveLesson),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
