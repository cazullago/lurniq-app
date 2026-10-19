import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/illustrations.dart' as ill;
import '../../widgets/ui.dart';
import '../feed/post_card.dart';
import '../messages/conversation_screen.dart';

/// Another person's profile, with per-field privacy respected.
/// Works for both students ([AppUser]) and marketplace tutors ([Tutor]):
/// when the id isn't a user, it falls back to the tutor record.
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

  Tutor? _tutorOf(AppStore store) {
    for (final t in store.tutors) {
      if (t.id == userId) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    if (me == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final user = store.userById(userId);
    if (user == null) {
      return _TutorProfile(userId: userId, tutor: _tutorOf(store));
    }
    final isOwn = me.id == user.id;
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

    final showEducation =
        user.educationLevel.isNotEmpty &&
            _canSee(me, user, 'educationLevel');

    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
        actions: [
          if (!isOwn)
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
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.washGradient(
                  Theme.of(context).brightness),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.heroGradient(
                        Theme.of(context).brightness),
                  ),
                  child: UserAvatar(
                      name: user.displayName,
                      avatarPath: user.avatarPath,
                      radius: 36),
                ),
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
                      if (showEducation)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7),
                            decoration: BoxDecoration(
                              color:
                                  scheme.tertiaryContainer,
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                              border: Border.all(
                                color: scheme.tertiary
                                    .withValues(
                                        alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Icon(
                                    Icons.school_rounded,
                                    size: 16,
                                    color: scheme
                                        .onTertiaryContainer),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    user.educationLevel,
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w800,
                                      fontSize: 13,
                                      color: scheme
                                          .onTertiaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isOwn)
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
          if (!isOwn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18),
                  label: const Text(S.messageButton),
                  onPressed: () =>
                      Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ConversationScreen(
                              otherUserId: userId),
                    ),
                  ),
                ),
              ),
            ),
          SectionHeader(title: S.tabPosts),
          if (posts.isEmpty)
            const ill.EmptyState(
              illustration: ill.IllustrationKind.chat,
              title: S.noPostsYet,
            ),
          ...posts.map((p) => PostCard(post: p)),
        ],
      ),
    );
  }
}

/// Fallback profile for ids that aren't [AppUser]s — marketplace tutors.
/// Shows the tutor's name, intro, subjects, and verification, plus a
/// Message button that opens a conversation with that tutor.
class _TutorProfile extends StatelessWidget {
  const _TutorProfile({required this.userId, required this.tutor});

  final String userId;
  final Tutor? tutor;

  @override
  Widget build(BuildContext context) {
    final t = tutor;
    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const ill.EmptyState(
          illustration: ill.IllustrationKind.compass,
          title: S.somethingWrong,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.heroGradient(
                      Theme.of(context).brightness),
                ),
                child:
                    UserAvatar(name: t.name, radius: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    VerificationBadge(
                        status: t.verification, compact: true),
                  ],
                ),
              ),
              if (t.isDemo) const DemoChip(),
            ],
          ),
          if (t.intro.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(t.intro,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (t.country.isNotEmpty)
                Chip(
                    avatar: const Icon(
                        Icons.public_outlined, size: 16),
                    label: Text(t.country)),
              if (t.experience.isNotEmpty)
                Chip(
                    avatar: const Icon(
                        Icons.workspace_premium_outlined,
                        size: 16),
                    label: Text(t.experience)),
              Chip(
                avatar: const Icon(Icons.star_rounded, size: 16),
                label: Text(
                    '${t.rating.toStringAsFixed(1)} (${t.reviewCount})'),
              ),
            ],
          ),
          if (t.subjects.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Subjects',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: t.subjects
                  .map((s) => Chip(
                      label: Text(s,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
            ),
          ],
          if (t.levels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Levels',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: t.levels
                  .map((l) => Chip(
                      label: Text(l,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(
                  Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text(S.messageButton),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ConversationScreen(otherUserId: userId),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
