import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'preview_screen.dart';

/// General post composer: type, subject, level, tags, images, preview.
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({super.key});

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  String _type = 'discussion';
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tags = TextEditingController();
  String? _subject;
  String? _level;
  final List<String> _images = [];
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tags.dispose();
    super.dispose();
  }

  List<String> get _tagList => _tags.text
      .split(',')
      .map((t) => t.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-'))
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _addImage(bool camera) async {
    final store = context.read<AppStore>();
    final path = await pickAndSaveImage(context, store.appDir, camera: camera);
    if (path != null) setState(() => _images.add(path));
  }

  void _pickImageSource() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text(S.takePhoto),
              onTap: () {
                Navigator.of(ctx).pop();
                _addImage(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(S.chooseFromGallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _addImage(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Post _draft(AppStore store) {
    final me = store.currentUser!;
    return Post(
      id: newId(),
      authorId: me.id,
      authorName: me.displayName,
      authorAvatar: me.avatarPath,
      type: _type,
      title: _title.text.trim(),
      body: _body.text.trim(),
      subject: _subject ?? '',
      level: _level ?? '',
      tags: _tagList,
      imagePaths: List.of(_images),
    );
  }

  void _preview() {
    if (_body.text.trim().isEmpty && _title.text.trim().isEmpty) {
      showSnack(context, S.bodyRequired);
      return;
    }
    final store = context.read<AppStore>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          post: _draft(store),
          publishLabel: S.publishPost,
          onPublish: _publish,
        ),
      ),
    );
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    try {
      await context.read<AppStore>().createPost(_draft(context.read<AppStore>()));
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        showSnack(context, S.postPublished);
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
        title: const Text(S.optionGeneralPost),
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
            Text(S.postType,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: C.postTypes
                  .where((t) => t['id'] != 'studyGroup' && t['id'] != 'resource')
                  .map(
                    (t) => ChoiceChip(
                      label: Text(t['label']!),
                      selected: _type == t['id'],
                      onSelected: (_) =>
                          setState(() => _type = t['id']!),
                    ),
                  )
                  .toList(),
            ),
            if (_type == 'question') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 20, color: scheme.secondary),
                    const SizedBox(width: 8),
                    const Expanded(
                        child: Text(S.integrityComposerTip,
                            style: TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.postTitleOptional,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              minLines: 5,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.postBody,
                hintText: S.postBodyHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LurniqDropdown<String>(
                    label: S.subject,
                    value: _subject,
                    items: stringMenuItems(C.subjects),
                    onChanged: (v) =>
                        setState(() => _subject = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LurniqDropdown<String>(
                    label: S.educationLevel,
                    value: _level,
                    items: stringMenuItems(C.educationLevels),
                    onChanged: (v) =>
                        setState(() => _level = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: S.tags,
                hintText: S.tagsHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(S.addImages,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.map(
                  (p) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(p),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: InkWell(
                          onTap: () {
                            deleteImageQuietly(p);
                            setState(() => _images.remove(p));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.clear_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _pickImageSource,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined,
                        color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
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
