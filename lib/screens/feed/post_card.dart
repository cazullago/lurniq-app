import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/tappable_name.dart';
import '../../widgets/ui.dart';
import 'post_detail_screen.dart';

/// Shared post card used by the feed, profile activity, and saved lists.
/// Images are decoded at a capped width so feeds stay fast.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.showTypeChip = true});

  final Post post;
  final bool showTypeChip;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final scheme = Theme.of(context).colorScheme;
    final liked = me != null && post.likes.contains(me.id);
    final saved = me != null && post.bookmarks.contains(me.id);
    final isAuthor = me != null && post.authorId == me.id;

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warm sunrise edge — the card's signature accent.
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient(
                  Theme.of(context).brightness),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      PostDetailScreen(postId: post.id)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  UserAvatar(
                      name: post.authorName,
                      avatarPath: post.authorAvatar,
                      radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: TappableName(
                                userId: post.authorId,
                                name: post.authorName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (post.isDemo) ...[
                              const SizedBox(width: 6),
                              const DemoChip(),
                            ],
                          ],
                        ),
                        Text(
                          timeAgo(post.createdAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (!isAuthor && me != null)
                    TextButton(
                      onPressed: () => me.followingIds.contains(post.authorId)
                          ? store.unfollow(post.authorId)
                          : store.follow(post.authorId),
                      child: Text(me.followingIds.contains(post.authorId)
                          ? S.following
                          : S.follow),
                    ),
                  _OverflowMenu(post: post, isAuthor: isAuthor),
                ],
              ),
              const SizedBox(height: 8),
              if (showTypeChip)
                Wrap(
                  spacing: 6,
                  children: [
                    _TypeChip(type: post.type),
                    if (post.subject.isNotEmpty)
                      Chip(
                        label: Text(post.subject,
                            style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (post.resolved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 14,
                                color: scheme.onSecondaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              S.resolved,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              if (showTypeChip) const SizedBox(height: 6),
              if (post.title.isNotEmpty)
                Text(
                  post.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              if (post.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  post.body,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (post.type == 'studyGroup')
                _GroupSnippet(post: post),
              if (post.imagePaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                _PostImage(path: post.imagePaths.first),
              ],
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                TagChips(tags: post.tags),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _Action(
                    icon: liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    label: '${post.likes.length}',
                    color: liked ? scheme.error : null,
                    onTap: () => store.toggleLike(post.id),
                  ),
                  _Action(
                    icon: Icons.chat_bubble_outline_rounded,
                    label:
                        '${store.commentsFor(post.id).length}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              PostDetailScreen(postId: post.id)),
                    ),
                  ),
                  _Action(
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    label: saved ? S.bookmarked : S.bookmark,
                    color: saved ? scheme.primary : null,
                    onTap: () => store.toggleBookmark(post.id),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        C.postTypeLabel(type),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _GroupSnippet extends StatelessWidget {
  const _GroupSnippet({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final scheme = Theme.of(context).colorScheme;
    final start = post.groupStartsAtUtc;
    if (start == null) return const SizedBox.shrink();
    final local = utcToViewer(start, me);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.event_outlined,
              color: scheme.secondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmtDateTime(local),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${post.groupFormat == 'online' ? S.groupOnline : S.groupInPerson}'
                  ' · ${post.groupDurationMin ?? 60} min'
                  ' · ${post.spotsLeft} ${S.spotsLeft}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (post.groupCancelled)
            Text(S.groupCancelled,
                style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w700))
          else if (me != null &&
              (post.participantIds.contains(me.id) ||
                  post.pendingIds.contains(me.id)))
            FilledButton.tonal(
              onPressed: () => store.leaveGroup(post.id),
              child: const Text(S.leaveGroup),
            )
          else
            FilledButton(
              onPressed: () => store.requestJoinGroup(post.id),
              child: const Text(S.joinGroup),
            ),
        ],
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        file,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        // Decode a capped width: feeds never hold full-res bitmaps.
        cacheWidth: 800,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: color ??
                    Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color ??
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.post, required this.isAuthor});

  final Post post;
  final bool isAuthor;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (v) async {
        switch (v) {
          case 'report':
            _reportDialog(context, store);
          case 'delete':
            final ok = await confirmDialog(
              context,
              title: S.deletePost,
              body: S.deletePostConfirm,
            );
            if (ok) {
              await store.deletePost(post.id);
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            }
          case 'block':
            final ok = await confirmDialog(
              context,
              title: S.blockUser,
              body: S.blockUserConfirm,
            );
            if (ok) {
              store.block(post.authorId);
              if (context.mounted) showSnack(context, S.userBlocked);
            }
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
            value: 'report', child: Text(S.report)),
        if (isAuthor)
          const PopupMenuItem(
              value: 'delete', child: Text(S.deletePost)),
        if (!isAuthor)
          const PopupMenuItem(
              value: 'block', child: Text(S.blockUser)),
      ],
    );
  }

  void _reportDialog(BuildContext context, AppStore store) {
    String reason = C.reportReasons.first;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(S.reportTitle),
          content: RadioGroup<String>(
            groupValue: reason,
            onChanged: (v) =>
                setState(() => reason = v ?? reason),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.reportReason,
                    style: Theme.of(ctx)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...C.reportReasons.map(
                  (r) => RadioListTile<String>(
                    value: r,
                    title:
                        Text(r, style: const TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(S.cancel),
            ),
            FilledButton(
              onPressed: () {
                store.addReport(
                  targetType: 'post',
                  targetId: post.id,
                  targetSummary:
                      '${post.authorName}: ${post.title.isNotEmpty ? post.title : post.body}'.characters
                          .take(80)
                          .toString(),
                  reason: reason,
                );
                Navigator.of(ctx).pop();
                showSnack(context, S.reportThanks);
              },
              child: const Text(S.report),
            ),
          ],
        ),
      ),
    );
  }
}
