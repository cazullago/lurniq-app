import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import '../feed/post_card.dart';

/// Another student's profile, with per-field privacy respected.
/// Messaging arrives in Phase 4 — there is intentionally no message button.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  bool _canSee(AppUser viewer, AppUser target, String field) {
    if (viewer.id == target.id) return true;
    final p = target.privacyFor(field);
    if (p == 'public') return true;
    if (p == 'followers') {
      return target.followingIds.contains(viewer.id) ||
          viewer.followingIds.contains(target.id);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final user = store.userById(userId);
    if (me == null || user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: S.somethingWrong,
        ),
      );
    }
    if (store.isBlocked(userId)) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.block_outlined,
          title: S.blockedUsers,
          actionLabel: S.unblock,
          onAction: () => store.unblock(userId),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final posts = store.posts
        .where((p) => p.authorId == userId && !p.hidden)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final following = me.followingIds.contains(userId);

    Widget field(String key, String value, {IconData? icon}) {
      if (value.isEmpty || !_canSee(me, user, key)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Expanded(child: Text(value)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'block') {
                final ok = await confirmDialog(
                  context,
                  title: S.blockUser,
                  body: S.blockUserConfirm,
                );
                if (ok) {
                  store.block(userId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    showSnack(context, S.userBlocked);
                  }
                }
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                  value: 'block', child: Text(S.blockUser)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                UserAvatar(
                    name: user.displayName,
                    avatarPath: user.avatarPath,
                    radius: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w800),
                      ),
                      Text('@${user.username}',
                          style: TextStyle(
                              color:
                                  scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => following
                      ? store.unfollow(userId)
                      : store.follow(userId),
                  child: Text(
                      following ? S.following : S.follow),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                field('bio', user.bio),
                field('country', user.country,
                    icon: Icons.public_outlined),
                field('educationLevel', user.educationLevel,
                    icon: Icons.school_outlined),
                field('school', user.school,
                    icon: Icons.business_outlined),
                if (_canSee(me, user, 'interests') &&
                    user.interests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.interests
                          .map((i) => Chip(
                              label: Text(i,
                                  style: const TextStyle(
                                      fontSize: 13))))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          SectionHeader(title: S.tabPosts),
          if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(S.noPostsYet),
            ),
          ...posts.map((p) => PostCard(post: p)),
        ],
      ),
    );
  }
}
