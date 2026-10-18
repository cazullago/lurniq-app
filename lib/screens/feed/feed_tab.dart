import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'post_card.dart';

/// Student learning community feed.
class FeedTab extends StatefulWidget {
  const FeedTab({super.key, this.onCompose});

  /// Called when the empty-state CTA is tapped (jumps to the Add Post tab).
  final VoidCallback? onCompose;

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final _search = TextEditingController();
  String _query = '';
  String? _type;
  String? _subject;
  String? _level;
  String _sort = 'newest';
  bool _sheetOpen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final posts = store.feedPosts(
      query: _query,
      subject: _subject,
      level: _level,
      type: _type,
      sort: _sort,
    );
    final announcements = store.activeAnnouncements;
    final hasFilters = _type != null || _subject != null || _level != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.feedTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: S.filters,
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: S.feedSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() {
                          _query = '';
                          _search.clear();
                        }),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (hasFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  if (_type != null)
                    _FilterChip(
                        label: C.postTypeLabel(_type!),
                        onClear: () =>
                            setState(() => _type = null)),
                  if (_subject != null)
                    _FilterChip(
                        label: _subject!,
                        onClear: () =>
                            setState(() => _subject = null)),
                  if (_level != null)
                    _FilterChip(
                        label: _level!,
                        onClear: () =>
                            setState(() => _level = null)),
                  TextButton(
                    onPressed: () => setState(() {
                      _type = null;
                      _subject = null;
                      _level = null;
                    }),
                    child: const Text(S.clearFilters),
                  ),
                ],
              ),
            ),
          Expanded(
            child: posts.isEmpty && announcements.isEmpty
                ? EmptyState(
                    icon: Icons.forum_outlined,
                    title: S.feedEmpty,
                    subtitle: S.feedEmptyHint,
                    actionLabel: S.createFirstPost,
                    onAction: widget.onCompose,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: posts.length + announcements.length,
                    itemBuilder: (context, i) {
                      if (i < announcements.length) {
                        return _AnnouncementBanner(
                            announcement: announcements[i]);
                      }
                      return PostCard(post: posts[i - announcements.length]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet() {
    if (_sheetOpen) return;
    _sheetOpen = true;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.filters,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              LurniqDropdown<String>(
                label: S.postType,
                value: _type,
                hint: S.all,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text(S.all)),
                  ...C.postTypes.map(
                    (t) => DropdownMenuItem(
                        value: t['id'], child: Text(t['label']!)),
                  ),
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 12),
              LurniqDropdown<String>(
                label: S.subject,
                value: _subject,
                hint: S.all,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text(S.all)),
                  ...stringMenuItems(C.subjects),
                ],
                onChanged: (v) => setState(() => _subject = v),
              ),
              const SizedBox(height: 12),
              LurniqDropdown<String>(
                label: S.educationLevel,
                value: _level,
                hint: S.all,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text(S.all)),
                  ...stringMenuItems(C.educationLevels),
                ],
                onChanged: (v) => setState(() => _level = v),
              ),
              const SizedBox(height: 12),
              LurniqDropdown<String>(
                label: S.sortBy,
                value: _sort,
                items: const [
                  DropdownMenuItem(
                      value: 'newest', child: Text(S.newest)),
                  DropdownMenuItem(
                      value: 'helpful',
                      child: Text(S.mostHelpful)),
                ],
                onChanged: (v) =>
                    setState(() => _sort = v ?? 'newest'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(S.done),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => _sheetOpen = false);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.clear_rounded, size: 16),
        onDeleted: onClear,
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${S.announcementLabel}: ${announcement.title}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(announcement.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
