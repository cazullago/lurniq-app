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
import '../messages/conversations_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart';

/// Own profile: identity, activity, settings entry point.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    if (me == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    final myPosts = store.myPosts();
    final saved = store.feedPosts(savedOnly: true);
    final following =
        me.followingIds.map(store.userById).whereType<AppUser>().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.profileTitle),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: DemoChip(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: S.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const SettingsScreen()),
            ),
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
                const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.heroGradient(
                        Theme.of(context).brightness),
                  ),
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(40),
                    onTap: () =>
                        _changeAvatar(context, store),
                    child: Stack(
                      children: [
                        UserAvatar(
                            name: me.displayName,
                            avatarPath: me.avatarPath,
                            radius: 36),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding:
                                const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons
                                    .photo_camera_outlined,
                                size: 14,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        me.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '@${me.username}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color:
                                    scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Stat(
                              value: '${myPosts.length}',
                              label: S.postsCount),
                          _Stat(
                              value:
                                  '${_followerCount(store, me.id)}',
                              label: S.followersCount),
                          _Stat(
                              value:
                                  '${me.followingIds.length}',
                              label: S.followingCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (me.bio.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(me.bio),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (me.country.isNotEmpty)
                  Chip(
                      avatar: const Icon(
                          Icons.public_outlined,
                          size: 16),
                      label: Text(me.country)),
                if (me.educationLevel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.tertiary
                            .withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 16,
                          color: scheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          me.educationLevel,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color:
                                scheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                Chip(
                    avatar: const Icon(
                        Icons.calendar_month_outlined,
                        size: 16),
                    label: Text(
                        '${S.memberSince} ${fmtDate(me.createdAt)}')),
              ],
            ),
          ),
          if (me.learningGoals.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(S.learningGoals,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                              fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: me.learningGoals
                        .map((g) => Chip(
                            label: Text(g,
                                style: const TextStyle(
                                    fontSize: 13))))
                        .toList(),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text(S.editProfile),
                onPressed: () =>
                    Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          const EditProfileScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: const Text(S.messages,
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(S.messagesDemoNote),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ConversationsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: S.tabPosts),
                    Tab(text: S.tabSaved),
                    Tab(text: S.tabFollowing),
                    Tab(text: S.tabCourses),
                  ],
                ),
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    children: [
                      _PostsList(posts: myPosts),
                      _PostsList(
                          posts: saved,
                          emptyTitle: S.noSavedYet,
                          emptyHint: S.noSavedHint,
                          illustration:
                              ill.IllustrationKind.compass),
                      _FollowingList(users: following),
                      const _CoursesPlaceholder(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _followerCount(AppStore store, String userId) => store.users
      .where((u) => u.followingIds.contains(userId))
      .length;

  Future<void> _changeAvatar(
      BuildContext context, AppStore store) async {
    final me = store.currentUser;
    if (me == null) return;
    final path = await pickAndSaveImage(
        context, store.appDir,
        camera: false);
    if (path != null) {
      if (me.avatarPath != null) {
        deleteImageQuietly(me.avatarPath);
      }
      me.avatarPath = path;
      await store.updateProfile(me);
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style:
                Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({
    required this.posts,
    this.emptyTitle = S.noPostsYet,
    this.emptyHint,
    this.illustration = ill.IllustrationKind.chat,
  });

  final List<Post> posts;
  final String emptyTitle;
  final String? emptyHint;
  final ill.IllustrationKind illustration;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return ill.EmptyState(
          illustration: illustration,
          title: emptyTitle,
          body: emptyHint);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: posts.length,
      itemBuilder: (context, i) =>
          PostCard(post: posts[i]),
    );
  }
}

class _FollowingList extends StatelessWidget {
  const _FollowingList({required this.users});

  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    if (users.isEmpty) {
      return const ill.EmptyState(
        illustration: ill.IllustrationKind.chat,
        title: S.noFollowingYet,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        return Card(
          margin: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          child: ListTile(
            leading: UserAvatar(
                name: u.displayName,
                avatarPath: u.avatarPath),
            title: Text(u.displayName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700)),
            subtitle: Text('@${u.username}'),
            trailing: TextButton(
              onPressed: () =>
                  store.unfollow(u.id),
              child: const Text(S.unfollow),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      UserProfileScreen(userId: u.id)),
            ),
          ),
        );
      },
    );
  }
}

class _CoursesPlaceholder extends StatelessWidget {
  const _CoursesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ill.EmptyState(
      illustration: ill.IllustrationKind.trophy,
      title: S.tabCourses,
      body: S.coursesPhase3Note,
    );
  }
}
