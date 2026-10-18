import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'preview_screen.dart';

/// Share-a-resource composer: notes, guides, flashcards, links.
class ComposeResourceScreen extends StatefulWidget {
  const ComposeResourceScreen({super.key});

  @override
  State<ComposeResourceScreen> createState() =>
      _ComposeResourceScreenState();
}

class _ComposeResourceScreenState extends State<ComposeResourceScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _link = TextEditingController();
  final _accessNote = TextEditingController();
  String? _subject;
  String? _level;
  String? _kind;
  bool _free = true;
  bool _busy = false;

  static const _kinds = [
    'Notes',
    'Study guide',
    'Practice questions',
    'Flashcards',
    'Link',
    'Other',
  ];

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _link.dispose();
    _accessNote.dispose();
    super.dispose();
  }

  Post? _draft(AppStore store) {
    if (_title.text.trim().isEmpty ||
        _desc.text.trim().isEmpty) {
      return null;
    }
    final me = store.currentUser!;
    return Post(
      id: newId(),
      authorId: me.id,
      authorName: me.displayName,
      authorAvatar: me.avatarPath,
      type: 'resource',
      title: _title.text.trim(),
      body: _desc.text.trim(),
      subject: _subject ?? '',
      level: _level ?? '',
      linkUrl:
          _link.text.trim().isEmpty ? null : _link.text.trim(),
      linkLabel: _link.text.trim().isEmpty ? null : S.openLink,
      resourceKind: _kind,
      freeAccess: _free,
      accessNote: _free ? '' : _accessNote.text.trim(),
    );
  }

  void _preview() {
    final store = context.read<AppStore>();
    final draft = _draft(store);
    if (draft == null) {
      showSnack(context, S.bodyRequired);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          post: draft,
          publishLabel: S.shareResource,
          onPublish: _publish,
        ),
      ),
    );
  }

  Future<void> _publish() async {
    final store = context.read<AppStore>();
    final draft = _draft(store);
    if (draft == null) return;
    setState(() => _busy = true);
    try {
      await store.createPost(draft);
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        showSnack(context, S.resourceShared);
      }
    } on StoreException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.optionResource),
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
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.resourceTitle,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.resourceDescription,
                hintText: S.resourceDescriptionHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LurniqDropdown<String>(
                    label: S.resourceKind,
                    value: _kind,
                    items: stringMenuItems(_kinds),
                    onChanged: (v) =>
                        setState(() => _kind = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LurniqDropdown<String>(
                    label: S.subject,
                    value: _subject,
                    items: stringMenuItems(C.subjects),
                    onChanged: (v) =>
                        setState(() => _subject = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LurniqDropdown<String>(
              label: S.educationLevel,
              value: _level,
              items: stringMenuItems(C.educationLevels),
              onChanged: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _link,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: S.resourceLink,
                hintText: 'https://…',
              ),
            ),
            const SizedBox(height: 16),
            Text(S.resourceAccess,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    icon: Icon(Icons.lock_open_outlined),
                    label: Text(S.resourceFree)),
                ButtonSegment(
                    value: false,
                    icon: Icon(Icons.lock_outline_rounded),
                    label: Text(S.resourceRestricted)),
              ],
              selected: {_free},
              onSelectionChanged: (s) =>
                  setState(() => _free = s.first),
            ),
            if (!_free) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _accessNote,
                decoration: const InputDecoration(
                  labelText: S.resourceRestriction,
                  hintText:
                      'e.g. free for followers, ask me for the file',
                ),
              ),
            ],
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
