import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/tappable_name.dart';
import '../../widgets/ui.dart';

/// Full post view: content, study-group management, comments + replies,
/// helpful-answer marking, and resolve controls.
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _comment = TextEditingController();
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final post = store.postById(widget.postId);
    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.forum_outlined,
          title: S.feedEmpty,
        ),
      );
    }
    final me = store.currentUser;
    final isAuthor = me != null && post.authorId == me.id;
    final comments =
        store.commentsFor(post.id).where((c) => c.parentId == null).toList();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(C.postTypeLabel(post.type)),
        actions: [if (post.isDemo) const DemoChip()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _postBody(context, store, post, isAuthor),
                if (post.type == 'question')
                  const _IntegrityCard(),
                if (post.type == 'studyGroup')
                  _GroupManager(post: post, isAuthor: isAuthor),
                SectionHeader(
                  title:
                      '${S.comments} (${store.commentsFor(post.id).length})',
                ),
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Text(
                      S.addCommentHint,
                      style: TextStyle(
                          color: scheme.onSurfaceVariant),
                    ),
                  ),
                ...comments.map((c) => _CommentTile(
                      comment: c,
                      post: post,
                      isAuthor: isAuthor,
                      onReply: (id, name) => setState(() {
                        _replyToId = id;
                        _replyToName = name;
                      }),
                    )),
              ],
            ),
          ),
          _commentBar(context, store, post),
        ],
      ),
    );
  }

  Widget _postBody(
      BuildContext context, AppStore store, Post post, bool isAuthor) {
    final scheme = Theme.of(context).colorScheme;
    final me = store.currentUser;
    final liked = me != null && post.likes.contains(me.id);
    final saved = me != null && post.bookmarks.contains(me.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                    name: post.authorName,
                    avatarPath: post.authorAvatar,
                    radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TappableName(
                          userId: post.authorId,
                          name: post.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      Text(
                        '${timeAgo(post.createdAt)}${post.subject.isNotEmpty ? ' · ${post.subject}' : ''}${post.level.isNotEmpty ? ' · ${post.level}' : ''}',
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
                    onPressed: () =>
                        me.followingIds.contains(post.authorId)
                            ? store.unfollow(post.authorId)
                            : store.follow(post.authorId),
                    child: Text(me.followingIds
                            .contains(post.authorId)
                        ? S.following
                        : S.follow),
                  ),
              ],
            ),
            if (post.title.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                post.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
            if (post.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(post.body,
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
            if (post.linkUrl != null &&
                post.linkUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(post.linkLabel?.isNotEmpty == true
                    ? post.linkLabel!
                    : S.openLink),
                onPressed: () async {
                  final uri = Uri.tryParse(post.linkUrl!);
                  if (uri != null) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
            if (post.type == 'resource') ...[
              const SizedBox(height: 8),
              _AccessRow(post: post),
            ],
            for (final pth in post.imagePaths) ...[
              const SizedBox(height: 10),
              _DetailImage(path: pth),
            ],
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              TagChips(tags: post.tags),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: Icon(liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded),
                  label: Text('${post.likes.length}'),
                  onPressed: () => store.toggleLike(post.id),
                ),
                OutlinedButton.icon(
                  icon: Icon(saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded),
                  label: Text(saved ? S.bookmarked : S.bookmark),
                  onPressed: () =>
                      store.toggleBookmark(post.id),
                ),
                if (isAuthor &&
                    (post.type == 'question' ||
                        post.type == 'discussion'))
                  OutlinedButton.icon(
                    icon: Icon(post.resolved
                        ? Icons.replay_rounded
                        : Icons.check_circle_outline_rounded),
                    label: Text(
                        post.resolved ? S.reopen : S.markResolved),
                    onPressed: () => store.setResolved(
                        post.id, !post.resolved),
                  ),
              ],
            ),
            if (post.resolved) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified_rounded,
                      size: 18, color: scheme.secondary),
                  const SizedBox(width: 6),
                  Text(S.resolved,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.secondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _commentBar(
      BuildContext context, AppStore store, Post post) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
              top: BorderSide(
                  color: scheme.outlineVariant
                      .withValues(alpha: 0.5))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyToId != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${S.reply} → $_replyToName',
                      style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => setState(() {
                      _replyToId = null;
                      _replyToName = null;
                    }),
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comment,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _replyToId == null
                          ? S.addCommentHint
                          : S.writeReplyHint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _submitComment(store, post),
                  child: const Text(S.postComment),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment(AppStore store, Post post) async {
    try {
      await store.addComment(
        postId: post.id,
        body: _comment.text,
        parentId: _replyToId,
      );
      _comment.clear();
      setState(() {
        _replyToId = null;
        _replyToName = null;
      });
    } on StoreException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }
}

class _IntegrityCard extends StatelessWidget {
  const _IntegrityCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.school_outlined, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.integrityTipTitle,
                  style:
                      const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(S.integrityTipBody,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
              post.freeAccess
                  ? Icons.lock_open_outlined
                  : Icons.lock_outline_rounded,
              size: 18,
              color: scheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              post.freeAccess
                  ? '${S.resourceFree}${post.resourceKind?.isNotEmpty == true ? ' · ${post.resourceKind}' : ''}'
                  : '${S.resourceRestricted}: ${post.accessNote}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => _FullImage(path: path)),
      ),
      child: Hero(
        tag: path,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheWidth: 1200,
            errorBuilder: (_, _, _) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  const _FullImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.viewPhoto)),
      body: Center(
        child: Hero(
          tag: path,
          child: InteractiveViewer(
            child: Image.file(File(path)),
          ),
        ),
      ),
    );
  }
}

/// Study-group join / participant management.
class _GroupManager extends StatelessWidget {
  const _GroupManager({required this.post, required this.isAuthor});

  final Post post;
  final bool isAuthor;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final scheme = Theme.of(context).colorScheme;
    final start = post.groupStartsAtUtc;
    if (start == null) return const SizedBox.shrink();
    final local = utcToViewer(start, me);
    final isParticipant =
        me != null && post.participantIds.contains(me.id);
    final isPending =
        me != null && post.pendingIds.contains(me.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined,
                    color: scheme.secondary),
                const SizedBox(width: 8),
                Text(
                  C.postTypeLabel('studyGroup'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _GRow(icon: Icons.event_outlined, value: fmtDateTime(local)),
            _GRow(
                icon: Icons.timer_outlined,
                value: '${post.groupDurationMin ?? 60} min'),
            _GRow(
                icon: post.groupFormat == 'online'
                    ? Icons.videocam_outlined
                    : Icons.place_outlined,
                value: post.groupFormat == 'online'
                    ? '${S.groupOnline}${post.groupLink?.isNotEmpty == true ? ' · ${post.groupLink}' : ''}'
                    : '${S.groupInPerson}${post.groupLocation?.isNotEmpty == true ? ' · ${post.groupLocation}' : ''}'),
            _GRow(
                icon: Icons.people_outline_rounded,
                value:
                    '${post.participantIds.length}${post.groupMaxParticipants != null ? ' / ${post.groupMaxParticipants}' : ''} ${S.participants.toLowerCase()} · ${post.spotsLeft} ${S.spotsLeft}'),
            Text(
              S.groupTimezoneNote,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (post.groupCancelled) ...[
              const SizedBox(height: 10),
              Text(S.groupCancelled,
                  style: TextStyle(
                      color: scheme.error,
                      fontWeight: FontWeight.w700)),
            ] else ...[
              const SizedBox(height: 12),
              if (isAuthor)
                Wrap(
                  spacing: 8,
                  children: [
                    if (post.pendingIds.isNotEmpty)
                      Text(
                          '${S.joinGroupPending}: ${post.pendingIds.length}'),
                    OutlinedButton.icon(
                      icon: const Icon(
                          Icons.cancel_outlined),
                      label:
                          const Text(S.cancelGroup),
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          title: S.cancelGroup,
                          body: S.cancelGroupConfirm,
                        );
                        if (ok) store.cancelGroup(post.id);
                      },
                    ),
                  ],
                )
              else if (isParticipant || isPending)
                OutlinedButton(
                  onPressed: () =>
                      store.leaveGroup(post.id),
                  child: Text(isPending
                      ? S.joinGroupPending
                      : S.leaveGroup),
                )
              else
                FilledButton(
                  onPressed: () =>
                      store.requestJoinGroup(post.id),
                  child: const Text(S.joinGroup),
                ),
              if (isAuthor && post.pendingIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(S.joinGroupPending,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700)),
                ...post.pendingIds.map((uid) {
                  final u = store.userById(uid);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(
                        name: u?.displayName ?? '?',
                        radius: 16),
                    title: Text(u?.displayName ?? uid),
                    trailing: FilledButton.tonal(
                      onPressed: () => store
                          .approveParticipant(post.id, uid),
                      child: const Text(S.approve),
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GRow extends StatelessWidget {
  const _GRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.post,
    required this.isAuthor,
    required this.onReply,
  });

  final FeedComment comment;
  final Post post;
  final bool isAuthor;
  final void Function(String id, String name) onReply;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final scheme = Theme.of(context).colorScheme;
    final liked =
        me != null && comment.likes.contains(me.id);
    final mine = me != null && comment.authorId == me.id;
    final replies = store.repliesFor(comment.id);

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                    name: comment.authorName, radius: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: TappableName(
                    userId: comment.authorId,
                    name: comment.authorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                if (comment.isHelpful)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13,
                            color:
                                scheme.onSecondaryContainer),
                        const SizedBox(width: 3),
                        Text(
                          S.helpfulAnswer,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                scheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (comment.isDemo) ...[
                  const SizedBox(width: 6),
                  const DemoChip(),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(comment.body),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  timeAgo(comment.createdAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () =>
                      store.toggleCommentLike(comment.id),
                  child: Row(
                    children: [
                      Icon(
                        liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        size: 16,
                        color: liked
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text('${comment.likes.length}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () =>
                      onReply(comment.id, comment.authorName),
                  child: Text(
                    S.reply,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (isAuthor && !comment.isHelpful)
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => store.markHelpful(
                        post.id, comment.id),
                    child: const Text(S.markHelpful,
                        style: TextStyle(fontSize: 12)),
                  ),
                if (mine)
                  IconButton(
                    icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: S.delete,
                        body: S.deleteCommentConfirm,
                      );
                      if (ok) {
                        await store
                            .deleteComment(comment.id);
                      }
                    },
                  ),
              ],
            ),
            for (final r in replies)
              Container(
                margin: const EdgeInsets.only(
                    left: 12, top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _ReplyRow(
                    reply: r, onDelete: mine || isAuthor
                        ? () async {
                            final ok =
                                await confirmDialog(
                              context,
                              title: S.delete,
                              body: S
                                  .deleteCommentConfirm,
                            );
                            if (ok) {
                              await store.deleteComment(
                                  r.id);
                            }
                          }
                        : null),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReplyRow extends StatelessWidget {
  const _ReplyRow({required this.reply, this.onDelete});

  final FeedComment reply;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(name: reply.authorName, radius: 13),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TappableName(
                userId: reply.authorId,
                name: reply.authorName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12),
              ),
              Text(reply.body,
                  style: const TextStyle(fontSize: 13)),
              Text(
                timeAgo(reply.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          InkWell(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.clear_rounded, size: 16),
            ),
          ),
      ],
    );
  }
}
