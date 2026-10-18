import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/json_store.dart';
import '../core/utils.dart';
import '../data/course_seed.dart';
import '../data/seed.dart';
import '../models/models.dart';

/// Single source of truth for the whole app (Phase 1: on-device JSON store).
///
/// Integration points for later phases are marked with [BACKEND], [PAYMENTS],
/// [AI], [PUSH] tags. Swapping the JsonBox persistence for Firestore only
/// requires changing [_saveNow]/[load] — every screen talks to this API.
class AppStore extends ChangeNotifier {
  AppStore._(this._dir, this._box, this._sessionBox);

  final Directory _dir;
  final JsonBox _box;
  final JsonBox _sessionBox;
  Timer? _saveTimer;
  bool _disposed = false;

  Directory get appDir => _dir;

  // ── Data ───────────────────────────────────────────────
  List<AppUser> users = [];
  List<Post> posts = [];
  List<FeedComment> comments = [];
  List<Tutor> tutors = [];
  List<TutorReview> tutorReviews = [];
  List<TutorInterest> tutorInterests = [];
  List<SubjectFolder> folders = [];
  List<Lesson> lessons = [];
  List<StudyTask> tasks = [];
  List<Report> reports = [];
  List<AdminLogEntry> adminLog = [];
  List<Announcement> announcements = [];
  // v2 collections
  List<Course> courses = [];
  List<CourseLesson> courseLessons = [];
  List<CourseEnrollment> enrollments = [];
  List<TutorBooking> bookings = [];
  List<LiveSession> liveSessions = [];
  List<QuizAttempt> quizAttempts = [];
  List<Conversation> conversations = [];
  List<ChatMessage> chatMessages = [];
  double commissionRate = C.defaultCommission;

  AppUser? currentUser;

  // ── Load / save ────────────────────────────────────────
  static Future<AppStore> load(Directory dir) async {
    final box = FileJsonBox(File('${dir.path}/${C.dataFileName}'));
    final sessionBox =
        FileJsonBox(File('${dir.path}/${C.sessionFileName}'));
    final store = AppStore._(dir, box, sessionBox);
    final data = await box.readMap();
    if (data.isEmpty || data['seeded'] != true) {
      store._seed();
    } else {
      store._fromJson(data);
    }
    final session = await sessionBox.readMap();
    final uid = session['userId'] as String?;
    if (uid != null) {
      store.currentUser = store._userById(uid);
    }
    final key = session['aiApiKey'] as String?;
    if (key != null && key.isNotEmpty) store._aiApiKey = key;
    return store;
  }

  /// In-memory variant for widget tests. Real async file IO deadlocks inside
  /// testWidgets' FakeAsync zone, so widget tests must not touch the disk.
  /// Pure `test()` suites (store_test.dart) keep using [load] with temp dirs.
  static Future<AppStore> loadForTest() async {
    final store = AppStore._(
        Directory.systemTemp, MemoryJsonBox(), MemoryJsonBox());
    store._seed();
    return store;
  }

  void _seed() {
    users = SeedData.demoUsers();
    tutors = SeedData.tutors();
    posts = SeedData.posts();
    comments = SeedData.comments();
    courses = CourseSeed.demoCourses();
    courseLessons = CourseSeed.demoLessons();
    liveSessions = CourseSeed.demoLiveSessions();
    commissionRate = C.defaultCommission;
    _scheduleSave();
  }

  void _fromJson(Map<String, dynamic> d) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
        (d[k] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
    users = list('users', AppUser.fromJson);
    posts = list('posts', Post.fromJson);
    comments = list('comments', FeedComment.fromJson);
    tutors = list('tutors', Tutor.fromJson);
    tutorReviews = list('tutorReviews', TutorReview.fromJson);
    tutorInterests = list('tutorInterests', TutorInterest.fromJson);
    folders = list('folders', SubjectFolder.fromJson);
    lessons = list('lessons', Lesson.fromJson);
    tasks = list('tasks', StudyTask.fromJson);
    reports = list('reports', Report.fromJson);
    adminLog = list('adminLog', AdminLogEntry.fromJson);
    announcements = list('announcements', Announcement.fromJson);
    courses = list('courses', Course.fromJson);
    courseLessons = list('courseLessons', CourseLesson.fromJson);
    enrollments = list('enrollments', CourseEnrollment.fromJson);
    bookings = list('bookings', TutorBooking.fromJson);
    liveSessions = list('liveSessions', LiveSession.fromJson);
    quizAttempts = list('quizAttempts', QuizAttempt.fromJson);
    conversations = list('conversations', Conversation.fromJson);
    chatMessages = list('chatMessages', ChatMessage.fromJson);
    commissionRate =
        ((d['commissionRate'] ?? C.defaultCommission) as num).toDouble();
    if (tutors.isEmpty) tutors = SeedData.tutors();
  }

  Map<String, dynamic> _toJson() => {
        'seeded': true,
        'version': 1,
        'commissionRate': commissionRate,
        'users': users.map((e) => e.toJson()).toList(),
        'posts': posts.map((e) => e.toJson()).toList(),
        'comments': comments.map((e) => e.toJson()).toList(),
        'tutors': tutors.map((e) => e.toJson()).toList(),
        'tutorReviews': tutorReviews.map((e) => e.toJson()).toList(),
        'tutorInterests': tutorInterests.map((e) => e.toJson()).toList(),
        'folders': folders.map((e) => e.toJson()).toList(),
        'lessons': lessons.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'reports': reports.map((e) => e.toJson()).toList(),
        'adminLog': adminLog.map((e) => e.toJson()).toList(),
        'announcements': announcements.map((e) => e.toJson()).toList(),
        'courses': courses.map((e) => e.toJson()).toList(),
        'courseLessons': courseLessons.map((e) => e.toJson()).toList(),
        'enrollments': enrollments.map((e) => e.toJson()).toList(),
        'bookings': bookings.map((e) => e.toJson()).toList(),
        'liveSessions': liveSessions.map((e) => e.toJson()).toList(),
        'quizAttempts': quizAttempts.map((e) => e.toJson()).toList(),
        'conversations': conversations.map((e) => e.toJson()).toList(),
        'chatMessages': chatMessages.map((e) => e.toJson()).toList(),
      };

  void _scheduleSave() {
    if (_disposed) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () => _saveNow());
  }

  Future<void> _saveNow() async {
    if (_disposed) return;
    await _box.writeMap(_toJson());
  }

  /// Forces a write — used by tests.
  Future<void> flush() async {
    _saveTimer?.cancel();
    await _saveNow();
  }

  Future<void> _saveSession() async {
    if (currentUser == null) {
      await _sessionBox.delete();
    } else {
      await _sessionBox.writeMap({
        'userId': currentUser!.id,
        // The AI API key is a device secret: it lives in the session box
        // (never synced, never in the data file) and is never logged.
        if (_aiApiKey != null) 'aiApiKey': _aiApiKey,
      });
    }
  }

  String? _aiApiKey;

  /// User-supplied OpenAI-compatible API key (Settings). Null = demo mode.
  String? get aiApiKey => _aiApiKey;

  Future<void> setAiApiKey(String? key) async {
    final v = key?.trim();
    _aiApiKey = (v == null || v.isEmpty) ? null : v;
    await _saveSession();
    notifyListeners();
  }

  void _mutate() {
    _scheduleSave();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    super.dispose();
  }

  // ── Auth ───────────────────────────────────────────────
  AppUser? _userById(String id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  AppUser? userById(String id) => _userById(id);

  /// [BACKEND] Replace with Firebase Auth; keep the session-restore contract.
  Future<void> signUp({
    required String displayName,
    required String username,
    String? email,
  }) async {
    final cleanName = displayName.trim();
    final cleanUser = username.trim().toLowerCase();
    if (cleanName.isEmpty) throw StoreException('Please enter a display name.');
    if (!RegExp(r'^[a-z0-9_.]{3,}$').hasMatch(cleanUser)) {
      throw StoreException('Usernames need at least 3 letters or numbers.');
    }
    if (users.any((u) => u.username.toLowerCase() == cleanUser)) {
      throw StoreException('That username is taken. Try another one.');
    }
    final user = AppUser(
      id: newId(),
      displayName: cleanName,
      username: cleanUser,
      email: email?.trim().isEmpty == true ? null : email?.trim(),
    );
    users.add(user);
    folders.addAll(SeedData.defaultFolders(user.id));
    currentUser = user;
    await _saveSession();
    _mutate();
  }

  Future<void> signIn(String username) async {
    final clean = username.trim().toLowerCase();
    final found = users.where((u) => u.username.toLowerCase() == clean);
    if (found.isEmpty) {
      throw StoreException('No account with that username on this device.');
    }
    currentUser = found.first;
    await _saveSession();
    _mutate();
  }

  /// One-tap demo account for trying the app.
  Future<void> signInDemo() async {
    const demoName = 'demo_explorer';
    final existing = users.where((u) => u.username == demoName);
    if (existing.isNotEmpty) {
      currentUser = existing.first;
    } else {
      final user = AppUser(
        id: newId(),
        displayName: 'Demo Explorer',
        username: demoName,
        bio: 'Trying out Lurniq.',
        country: '',
      );
      users.add(user);
      folders.addAll(SeedData.defaultFolders(user.id));
      currentUser = user;
    }
    await _saveSession();
    _mutate();
  }

  Future<void> signOut() async {
    currentUser = null;
    await _saveSession();
    _mutate();
  }

  Future<void> updateProfile(AppUser updated) async {
    final i = users.indexWhere((u) => u.id == updated.id);
    if (i >= 0) users[i] = updated;
    if (currentUser?.id == updated.id) currentUser = updated;
    _mutate();
  }

  /// Permanently removes the account and everything it created on device.
  Future<void> deleteAccount() async {
    final me = currentUser;
    if (me == null) return;
    users.removeWhere((u) => u.id == me.id);
    posts.removeWhere((p) => p.authorId == me.id);
    comments.removeWhere((c) => c.authorId == me.id);
    final lessonPaths =
        lessons.where((l) => l.ownerId == me.id).map((l) => l.photoPath);
    for (final pth in lessonPaths) {
      deleteImageQuietly(pth);
    }
    lessons.removeWhere((l) => l.ownerId == me.id);
    final taskPaths =
        tasks.where((t) => t.ownerId == me.id).map((t) => t.photoPath);
    for (final pth in taskPaths) {
      deleteImageQuietly(pth);
    }
    tasks.removeWhere((t) => t.ownerId == me.id);
    folders.removeWhere((f) => f.ownerId == me.id);
    for (final p in posts) {
      p.likes.remove(me.id);
      p.bookmarks.remove(me.id);
      p.participantIds.remove(me.id);
      p.pendingIds.remove(me.id);
    }
    for (final c in comments) {
      c.likes.remove(me.id);
    }
    for (final u in users) {
      u.followingIds.remove(me.id);
      u.blockedIds.remove(me.id);
    }
    currentUser = null;
    await _saveSession();
    _mutate();
  }

  void follow(String userId) {
    final me = currentUser;
    if (me == null || me.id == userId || me.followingIds.contains(userId)) {
      return;
    }
    me.followingIds.add(userId);
    _mutate();
  }

  void unfollow(String userId) {
    currentUser?.followingIds.remove(userId);
    _mutate();
  }

  void block(String userId) {
    final me = currentUser;
    if (me == null || me.id == userId || me.blockedIds.contains(userId)) return;
    me.blockedIds.add(userId);
    me.followingIds.remove(userId);
    _mutate();
  }

  void unblock(String userId) {
    currentUser?.blockedIds.remove(userId);
    _mutate();
  }

  bool isBlocked(String userId) =>
      currentUser?.blockedIds.contains(userId) ?? false;

  // ── Feed ───────────────────────────────────────────────

  /// Posts visible to the current viewer (hidden + blocked authors filtered).
  List<Post> visiblePosts() {
    final blocked = currentUser?.blockedIds.toSet() ?? <String>{};
    return posts
        .where((p) => !p.hidden && !blocked.contains(p.authorId))
        .toList();
  }

  List<Post> feedPosts({
    String? query,
    String? subject,
    String? level,
    String? type,
    String sort = 'newest',
    bool savedOnly = false,
  }) {
    final me = currentUser;
    var list = visiblePosts();
    if (savedOnly && me != null) {
      list = list.where((p) => p.bookmarks.contains(me.id)).toList();
    }
    if (type != null && type.isNotEmpty) {
      list = list.where((p) => p.type == type).toList();
    }
    if (subject != null && subject.isNotEmpty) {
      list = list.where((p) => p.subject == subject).toList();
    }
    if (level != null && level.isNotEmpty) {
      list = list.where((p) => p.level == level).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((p) {
        final hay =
            '${p.title} ${p.body} ${p.subject} ${p.tags.join(' ')} ${p.authorName}'
                .toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    if (sort == 'helpful') {
      list.sort((a, b) =>
          (b.likes.length + _commentCount(b.id) * 2)
              .compareTo(a.likes.length + _commentCount(a.id) * 2));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  int _commentCount(String postId) =>
      comments.where((c) => c.postId == postId).length;

  List<Post> myPosts() {
    final me = currentUser;
    if (me == null) return [];
    final list =
        posts.where((p) => p.authorId == me.id && !p.hidden).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Post> myGroups() {
    final me = currentUser;
    if (me == null) return [];
    final list = posts
        .where((p) =>
            p.type == 'studyGroup' &&
            !p.hidden &&
            (p.authorId == me.id ||
                p.participantIds.contains(me.id) ||
                p.pendingIds.contains(me.id)))
        .toList();
    list.sort((a, b) {
      final da = a.groupStartsAtUtc;
      final db = b.groupStartsAtUtc;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  Future<Post> createPost(Post draft) async {
    final me = currentUser;
    if (me == null) throw StoreException('Please sign in first.');
    draft.authorId = me.id;
    draft.authorName = me.displayName;
    draft.authorAvatar = me.avatarPath;
    draft.updatedAt = DateTime.now();
    if (draft.type == 'studyGroup' &&
        draft.participantIds.isEmpty) {
      // The organizer is always a participant of their own session.
      draft.participantIds.add(me.id);
    }
    posts.insert(0, draft);
    _mutate();
    return draft;
  }

  Future<void> updatePost(Post updated) async {
    final i = posts.indexWhere((p) => p.id == updated.id);
    if (i < 0) return;
    updated.updatedAt = DateTime.now();
    posts[i] = updated;
    _mutate();
  }

  Future<void> deletePost(String id) async {
    final post = _postById(id);
    if (post != null) {
      for (final pth in post.imagePaths) {
        deleteImageQuietly(pth);
      }
    }
    posts.removeWhere((p) => p.id == id);
    comments.removeWhere((c) => c.postId == id);
    _mutate();
  }

  Post? _postById(String id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Post? postById(String id) => _postById(id);

  void toggleLike(String postId) {
    final me = currentUser;
    final post = _postById(postId);
    if (me == null || post == null) return;
    if (post.likes.contains(me.id)) {
      post.likes.remove(me.id);
    } else {
      post.likes.add(me.id);
    }
    _mutate();
  }

  void toggleBookmark(String postId) {
    final me = currentUser;
    final post = _postById(postId);
    if (me == null || post == null) return;
    if (post.bookmarks.contains(me.id)) {
      post.bookmarks.remove(me.id);
    } else {
      post.bookmarks.add(me.id);
    }
    _mutate();
  }

  // Comments
  List<FeedComment> commentsFor(String postId) {
    final list = comments.where((c) => c.postId == postId).toList();
    list.sort((a, b) {
      if (a.isHelpful != b.isHelpful) return a.isHelpful ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  List<FeedComment> repliesFor(String commentId) {
    final list =
        comments.where((c) => c.parentId == commentId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<FeedComment> addComment({
    required String postId,
    required String body,
    String? parentId,
  }) async {
    final me = currentUser;
    if (me == null) throw StoreException('Please sign in first.');
    final clean = body.trim();
    if (clean.isEmpty) throw StoreException('Please write something first.');
    final comment = FeedComment(
      id: newId(),
      postId: postId,
      authorId: me.id,
      authorName: me.displayName,
      body: clean,
      parentId: parentId,
    );
    comments.add(comment);
    _mutate();
    return comment;
  }

  void toggleCommentLike(String commentId) {
    final me = currentUser;
    if (me == null) return;
    for (final c in comments) {
      if (c.id == commentId) {
        if (c.likes.contains(me.id)) {
          c.likes.remove(me.id);
        } else {
          c.likes.add(me.id);
        }
        break;
      }
    }
    _mutate();
  }

  Future<void> deleteComment(String commentId) async {
    comments.removeWhere(
        (c) => c.id == commentId || c.parentId == commentId);
    for (final p in posts) {
      if (p.helpfulCommentId == commentId) p.helpfulCommentId = null;
    }
    _mutate();
  }

  /// Only the post author can mark the helpful answer.
  void markHelpful(String postId, String commentId) {
    final me = currentUser;
    final post = _postById(postId);
    if (me == null || post == null || post.authorId != me.id) return;
    for (final c in comments.where((c) => c.postId == postId)) {
      c.isHelpful = c.id == commentId;
    }
    post.helpfulCommentId = commentId;
    _mutate();
  }

  void setResolved(String postId, bool resolved) {
    final me = currentUser;
    final post = _postById(postId);
    if (me == null || post == null || post.authorId != me.id) return;
    post.resolved = resolved;
    _mutate();
  }

  void addReport({
    required String targetType,
    required String targetId,
    required String targetSummary,
    required String reason,
  }) {
    final me = currentUser;
    reports.add(Report(
      id: newId(),
      targetType: targetType,
      targetId: targetId,
      targetSummary: targetSummary,
      reporterId: me?.id ?? '',
      reason: reason,
    ));
    _mutate();
  }

  // Study groups
  void requestJoinGroup(String postId) {
    final me = currentUser;
    final post = _postById(postId);
    if (me == null || post == null || post.groupCancelled) return;
    if (post.participantIds.contains(me.id) ||
        post.pendingIds.contains(me.id)) {
      return;
    }
    if (post.spotsLeft > 0) {
      post.participantIds.add(me.id);
    } else {
      post.pendingIds.add(me.id);
    }
    _mutate();
  }

  void leaveGroup(String postId) {
    final me = currentUser;
    final post = _postById(postId);
    if (me == null || post == null) return;
    post.participantIds.remove(me.id);
    post.pendingIds.remove(me.id);
    _mutate();
  }

  void approveParticipant(String postId, String userId) {
    final me = currentUser;
    final post = _postById(postId);
    if (me == null || post == null || post.authorId != me.id) return;
    if (post.spotsLeft <= 0) return;
    post.pendingIds.remove(userId);
    if (!post.participantIds.contains(userId)) {
      post.participantIds.add(userId);
    }
    _mutate();
  }

  void cancelGroup(String postId) {
    final me = currentUser;
    final post = _postById(postId);
    if (me == null || post == null || post.authorId != me.id) return;
    post.groupCancelled = true;
    _mutate();
  }

  // ── Tutors ─────────────────────────────────────────────

  List<Tutor> findTutors({
    String? query,
    String? subject,
    String? level,
    String? country,
    String? language,
    bool freeOnly = false,
    double? maxPrice,
    double? minRating,
    String sort = 'rating',
  }) {
    var list = tutors.toList();
    if (subject != null && subject.isNotEmpty) {
      list = list.where((t) => t.subjects.contains(subject)).toList();
    }
    if (level != null && level.isNotEmpty) {
      list = list.where((t) => t.levels.contains(level)).toList();
    }
    if (country != null && country.isNotEmpty) {
      list = list
          .where(
              (t) => t.country.toLowerCase() == country.toLowerCase())
          .toList();
    }
    if (language != null && language.isNotEmpty) {
      list = list.where((t) => t.languages.contains(language)).toList();
    }
    if (freeOnly) list = list.where((t) => t.priceUsd == 0).toList();
    if (maxPrice != null) {
      list = list.where((t) => t.priceUsd <= maxPrice).toList();
    }
    if (minRating != null && minRating > 0) {
      list = list.where((t) => t.rating >= minRating).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((t) {
        final hay =
            '${t.name} ${t.intro} ${t.subjects.join(' ')} ${t.country}'
                .toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    switch (sort) {
      case 'priceLow':
        list.sort((a, b) => a.priceUsd.compareTo(b.priceUsd));
      case 'priceHigh':
        list.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
      case 'rating':
      default:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  Tutor? tutorById(String id) {
    for (final t in tutors) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<TutorReview> reviewsFor(String tutorId) {
    final list =
        tutorReviews.where((r) => r.tutorId == tutorId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> addTutorReview({
    required String tutorId,
    required double rating,
    required String text,
  }) async {
    final me = currentUser;
    if (me == null) throw StoreException('Please sign in first.');
    final clean = text.trim();
    if (clean.isEmpty) throw StoreException('Please write a review.');
    tutorReviews.add(TutorReview(
      id: newId(),
      tutorId: tutorId,
      authorName: me.displayName,
      rating: rating,
      text: clean,
    ));
    final tutor = tutorById(tutorId);
    if (tutor != null) {
      tutor.reviewCount += 1;
      // Blend the new rating into the stored aggregate.
      tutor.rating = double.parse(
          ((tutor.rating * (tutor.reviewCount - 1) + rating) /
                  tutor.reviewCount)
              .toStringAsFixed(1));
    }
    _mutate();
  }

  Future<void> addTutorInterest({
    required String name,
    required String contact,
    required String subjects,
  }) async {
    if (name.trim().isEmpty || contact.trim().isEmpty) {
      throw StoreException('Please add your name and contact info.');
    }
    tutorInterests.add(TutorInterest(
      id: newId(),
      name: name.trim(),
      contact: contact.trim(),
      subjects: subjects.trim(),
    ));
    _mutate();
  }

  // ── Planner ────────────────────────────────────────────

  List<SubjectFolder> get myFolders {
    final me = currentUser;
    if (me == null) return [];
    final list =
        folders.where((f) => f.ownerId == me.id).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  SubjectFolder? folderById(String id) {
    for (final f in folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  Future<SubjectFolder> addFolder({
    required String name,
    required int colorValue,
    required String icon,
  }) async {
    final me = currentUser;
    if (me == null) throw StoreException('Please sign in first.');
    final clean = name.trim();
    if (clean.isEmpty) throw StoreException('Please name your subject.');
    final existing = myFolders;
    final folder = SubjectFolder(
      id: newId(),
      ownerId: me.id,
      name: clean,
      colorValue: colorValue,
      icon: icon,
      order: existing.length,
    );
    folders.add(folder);
    _mutate();
    return folder;
  }

  Future<void> renameFolder(
    String id, {
    required String name,
    required int colorValue,
    required String icon,
  }) async {
    final folder = folderById(id);
    if (folder == null) return;
    final clean = name.trim();
    if (clean.isEmpty) throw StoreException('Please name your subject.');
    folder.name = clean;
    folder.colorValue = colorValue;
    folder.icon = icon;
    _mutate();
  }

  Future<void> deleteFolder(String id) async {
    final doomed =
        lessons.where((l) => l.folderId == id).toList();
    for (final l in doomed) {
      deleteImageQuietly(l.photoPath);
    }
    lessons.removeWhere((l) => l.folderId == id);
    for (final t in tasks) {
      if (t.folderId == id) t.folderId = null;
    }
    folders.removeWhere((f) => f.id == id);
    final mine = myFolders;
    for (var i = 0; i < mine.length; i++) {
      mine[i].order = i;
    }
    _mutate();
  }

  /// Moves a folder in the user's ordering. [newIndex] is the insertion
  /// index in the already-updated list (as provided by
  /// ReorderableListView.onReorderItem) — no extra adjustment needed.
  Future<void> moveFolder(int oldIndex, int newIndex) async {
    final mine = myFolders;
    if (oldIndex < 0 ||
        oldIndex >= mine.length ||
        newIndex < 0 ||
        newIndex > mine.length) {
      return;
    }
    final item = mine.removeAt(oldIndex);
    mine.insert(newIndex.clamp(0, mine.length), item);
    for (var i = 0; i < mine.length; i++) {
      mine[i].order = i;
    }
    _mutate();
  }

  List<Lesson> lessonsIn(String folderId) {
    final me = currentUser;
    if (me == null) return [];
    final list = lessons
        .where((l) => l.ownerId == me.id && l.folderId == folderId)
        .toList();
    list.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
    return list;
  }

  List<Lesson> searchLessons(String query) {
    final me = currentUser;
    final q = query.trim().toLowerCase();
    if (me == null || q.isEmpty) return [];
    final list = lessons.where((l) {
      if (l.ownerId != me.id) return false;
      final hay =
          '${l.title} ${l.notes} ${l.tags.join(' ')}'.toLowerCase();
      return hay.contains(q);
    }).toList();
    list.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
    return list;
  }

  Future<Lesson> addLesson({
    required String folderId,
    required String title,
    required String photoPath,
    String notes = '',
    List<String> tags = const [],
    DateTime? lessonDate,
  }) async {
    final me = currentUser;
    if (me == null) throw StoreException('Please sign in first.');
    final clean = title.trim();
    if (clean.isEmpty) throw StoreException('Please add a lesson title.');
    if (photoPath.isEmpty) throw StoreException('Please add a photo.');
    final lesson = Lesson(
      id: newId(),
      ownerId: me.id,
      folderId: folderId,
      title: clean,
      photoPath: photoPath,
      notes: notes.trim(),
      tags: tags,
      lessonDate: lessonDate ?? DateTime.now(),
    );
    lessons.add(lesson);
    _mutate();
    return lesson;
  }

  Future<void> updateLesson(Lesson updated) async {
    final i = lessons.indexWhere((l) => l.id == updated.id);
    if (i < 0) return;
    lessons[i] = updated;
    _mutate();
  }

  Future<void> deleteLesson(String id) async {
    final lesson = lessons.where((l) => l.id == id);
    for (final l in lesson) {
      deleteImageQuietly(l.photoPath);
    }
    lessons.removeWhere((l) => l.id == id);
    _mutate();
  }

  // Tasks
  List<StudyTask> get myTasks {
    final me = currentUser;
    if (me == null) return [];
    return tasks.where((t) => t.ownerId == me.id).toList();
  }

  List<StudyTask> sortedTasks(List<StudyTask> input) {
    final list = input.toList();
    list.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final da = a.dueAtLocal;
      final db = b.dueAtLocal;
      if (da == null && db == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  List<StudyTask> get overdueTasks =>
      myTasks.where((t) => t.isOverdue).toList()
        ..sort((a, b) => a.dueAtLocal!.compareTo(b.dueAtLocal!));

  List<StudyTask> upcomingTasks({int days = 7}) {
    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    final list = myTasks.where((t) {
      if (t.isDone || t.dueAtLocal == null) return false;
      return t.dueAtLocal!.isAfter(now) &&
          t.dueAtLocal!.isBefore(end);
    }).toList();
    list.sort((a, b) => a.dueAtLocal!.compareTo(b.dueAtLocal!));
    return list;
  }

  List<StudyTask> tasksForDay(DateTime day) {
    final list = myTasks.where((t) {
      final d = t.dueAtLocal;
      return d != null &&
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    }).toList();
    return sortedTasks(list);
  }

  Future<StudyTask> addTask({
    required String title,
    String? folderId,
    String instructions = '',
    DateTime? dueAtLocal,
    String priority = 'medium',
    String notes = '',
    String? photoPath,
    bool reminder = false,
  }) async {
    final me = currentUser;
    if (me == null) throw StoreException('Please sign in first.');
    final clean = title.trim();
    if (clean.isEmpty) throw StoreException('Please add a task title.');
    final task = StudyTask(
      id: newId(),
      ownerId: me.id,
      title: clean,
      folderId: folderId,
      instructions: instructions.trim(),
      dueAtLocal: dueAtLocal,
      priority: priority,
      notes: notes.trim(),
      photoPath: photoPath,
      reminder: reminder,
    );
    tasks.add(task);
    _mutate();
    return task;
  }

  Future<void> updateTask(StudyTask updated) async {
    final i = tasks.indexWhere((t) => t.id == updated.id);
    if (i < 0) return;
    tasks[i] = updated;
    _mutate();
  }

  Future<void> deleteTask(String id) async {
    final task = tasks.where((t) => t.id == id);
    for (final t in task) {
      deleteImageQuietly(t.photoPath);
    }
    tasks.removeWhere((t) => t.id == id);
    _mutate();
  }

  void setTaskStatus(String id, String status) {
    for (final t in tasks) {
      if (t.id == id) {
        t.status = status;
        t.completedAt = status == 'done' ? DateTime.now() : null;
        break;
      }
    }
    _mutate();
  }

  // ── Admin ──────────────────────────────────────────────
  //
  // Demo build: passcode gate. PRODUCTION MUST enforce admin roles
  // server-side ([BACKEND]) — the hidden gesture alone is not protection.

  bool verifyAdmin(String code) {
    final ok = code.trim() == C.adminPasscode;
    if (ok) logAdmin('admin_login', 'Administrator signed in.');
    return ok;
  }

  void logAdmin(String action, String detail) {
    adminLog.insert(
        0, AdminLogEntry(id: newId(), action: action, detail: detail));
    if (adminLog.length > 500) {
      adminLog.removeRange(500, adminLog.length);
    }
    _scheduleSave();
    notifyListeners();
  }

  void setCommissionRate(double value) {
    final clamped = value.clamp(0.0, 0.9);
    final old = commissionRate;
    commissionRate = clamped;
    logAdmin('commission_changed',
        'Commission changed from ${(old * 100).toStringAsFixed(1)}% to ${(clamped * 100).toStringAsFixed(1)}%.');
  }

  List<Report> get openReports =>
      reports.where((r) => r.status == 'open').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void resolveReport(String id, String action) {
    // action: 'dismissed' | 'actioned'
    for (final r in reports) {
      if (r.id == id) {
        r.status = action;
        if (action == 'actioned' && r.targetType == 'post') {
          final post = _postById(r.targetId);
          if (post != null) post.hidden = true;
        }
        logAdmin('report_$action',
            'Report ${r.id} ($action): ${r.targetSummary}');
        break;
      }
    }
    _mutate();
  }

  List<Announcement> get activeAnnouncements =>
      announcements.where((a) => a.active).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void addAnnouncement(String title, String body) {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      throw StoreException('Please add a title and message.');
    }
    announcements.add(Announcement(
        id: newId(), title: title.trim(), body: body.trim()));
    logAdmin('announcement_created', 'Published: ${title.trim()}');
    _mutate();
  }

  void toggleAnnouncement(String id) {
    for (final a in announcements) {
      if (a.id == id) {
        a.active = !a.active;
        logAdmin('announcement_toggled',
            '${a.active ? 'Activated' : 'Deactivated'}: ${a.title}');
        break;
      }
    }
    _mutate();
  }

  void deleteAnnouncement(String id) {
    announcements.removeWhere((a) => a.id == id);
    logAdmin('announcement_deleted', 'Deleted announcement $id');
    _mutate();
  }

  Map<String, int> get stats => {
        'users': users.length,
        'posts': posts.length,
        'comments': comments.length,
        'tutors': tutors.length,
        'lessons': lessons.length,
        'tasks': tasks.length,
        'openReports': openReports.length,
        'tutorInterests': tutorInterests.length,
      };

  /// Removes seeded demo content. The user's own data is untouched.
  Future<void> clearDemoContent() async {
    for (final p in posts.where((p) => p.isDemo)) {
      for (final pth in p.imagePaths) {
        deleteImageQuietly(pth);
      }
    }
    final demoPostIds =
        posts.where((p) => p.isDemo).map((p) => p.id).toSet();
    posts.removeWhere((p) => p.isDemo);
    comments.removeWhere(
        (c) => c.isDemo || demoPostIds.contains(c.postId));
    courses.removeWhere((c) => c.isDemo);
    courseLessons.removeWhere(
        (l) => courses.every((c) => c.id != l.courseId));
    liveSessions.removeWhere((s) => s.isDemo);
    quizAttempts.removeWhere((a) => a.isDemo);
    conversations.removeWhere((c) => c.isDemo);
    chatMessages.removeWhere((m) => m.isDemo);
    users.removeWhere((u) => u.demoSeed);
    _mutate();
  }

  // ── v2: theme & settings ───────────────────────────────

  ThemeModeSetting get themeModeSetting {
    final m = currentUser?.themeMode ?? 'system';
    return ThemeModeSetting.values.firstWhere(
      (e) => e.name == m,
      orElse: () => ThemeModeSetting.system,
    );
  }

  Future<void> setThemeMode(ThemeModeSetting mode) async {
    final u = currentUser;
    if (u == null) return;
    u.themeMode = mode.name;
    await updateProfile(u);
  }

  // ── v2: tasks (types, Done folder, grades) ─────────────

  List<StudyTask> openTasks() {
    final uid = currentUser?.id;
    return tasks
        .where((t) => t.ownerId == uid && !t.isDone)
        .toList()
      ..sort((a, b) => _taskSort(a, b));
  }

  List<StudyTask> doneTasks() {
    final uid = currentUser?.id;
    return tasks
        .where((t) => t.ownerId == uid && t.isDone)
        .toList()
      ..sort((a, b) =>
          (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
  }

  int _taskSort(StudyTask a, StudyTask b) {
    int prio(String p) =>
        p == 'high' ? 0 : (p == 'medium' ? 1 : 2);
    final ap = prio(a.priority), bp = prio(b.priority);
    if (ap != bp) return ap - bp;
    final ad = a.dueAtLocal, bd = b.dueAtLocal;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  }

  StudyTask? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> completeTask(String id) async {
    final t = taskById(id);
    if (t == null) return;
    t.status = 'done';
    t.completedAt = DateTime.now();
    _mutate();
  }

  Future<void> reopenTask(String id) async {
    final t = taskById(id);
    if (t == null) return;
    t.status = 'todo';
    t.completedAt = null;
    _mutate();
  }

  Future<void> saveGrade(
    String id, {
    required String score,
    String note = '',
    String? photoPath,
  }) async {
    final t = taskById(id);
    if (t == null) return;
    t.gradeScore = score.trim();
    t.gradeNote = note.trim();
    if (photoPath != null) t.gradePhotoPath = photoPath;
    _mutate();
  }

  // ── v2: courses ────────────────────────────────────────

  List<Course> visibleCourses({
    String? subject,
    String? level,
    String? query,
    bool? freeOnly,
  }) {
    final q = (query ?? '').trim().toLowerCase();
    final list = courses.where((c) {
      if (!c.published) return false;
      if (subject != null && subject.isNotEmpty && c.subject != subject) {
        return false;
      }
      if (level != null && level.isNotEmpty && c.level != level) return false;
      if (freeOnly == true && c.priceUsd > 0) return false;
      if (q.isNotEmpty) {
        final hay = '${c.title} ${c.description} ${c.subject}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
    return list;
  }

  Course? courseById(String id) {
    for (final c in courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<CourseLesson> lessonsFor(String courseId) {
    final list =
        courseLessons.where((l) => l.courseId == courseId).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<Course> createCourse(Course draft) async {
    courses.add(draft);
    _mutate();
    return draft;
  }

  Future<void> updateCourse(Course updated) async {
    final i = courses.indexWhere((c) => c.id == updated.id);
    if (i >= 0) {
      courses[i] = updated;
      _mutate();
    }
  }

  Future<void> deleteCourse(String id) async {
    courses.removeWhere((c) => c.id == id);
    courseLessons.removeWhere((l) => l.courseId == id);
    enrollments.removeWhere((e) => e.courseId == id);
    _mutate();
  }

  Future<void> setCoursePublished(String id, bool published) async {
    final c = courseById(id);
    if (c == null) return;
    c.published = published;
    _mutate();
  }

  Future<void> saveCourseLesson(CourseLesson lesson) async {
    final i = courseLessons.indexWhere((l) => l.id == lesson.id);
    if (i >= 0) {
      courseLessons[i] = lesson;
    } else {
      courseLessons.add(lesson);
    }
    _mutate();
  }

  Future<void> deleteCourseLesson(String id) async {
    courseLessons.removeWhere((l) => l.id == id);
    _mutate();
  }

  bool isEnrolled(String courseId) {
    final uid = currentUser?.id;
    return enrollments
        .any((e) => e.courseId == courseId && e.studentId == uid);
  }

  CourseEnrollment? enrollmentFor(String courseId) {
    final uid = currentUser?.id;
    for (final e in enrollments) {
      if (e.courseId == courseId && e.studentId == uid) return e;
    }
    return null;
  }

  Future<void> enrollInCourse(String courseId) async {
    final uid = currentUser?.id;
    if (uid == null || isEnrolled(courseId)) return;
    enrollments.add(CourseEnrollment(
      id: newId(),
      courseId: courseId,
      studentId: uid,
    ));
    final c = courseById(courseId);
    if (c != null) c.enrollmentCount++;
    _mutate();
  }

  Future<void> markLessonDone(String courseId, String lessonId) async {
    final e = enrollmentFor(courseId);
    if (e == null || e.doneLessonIds.contains(lessonId)) return;
    e.doneLessonIds.add(lessonId);
    _mutate();
  }

  double courseProgress(String courseId) {
    final lessons = lessonsFor(courseId);
    if (lessons.isEmpty) return 0;
    final e = enrollmentFor(courseId);
    if (e == null) return 0;
    final done =
        lessons.where((l) => e.doneLessonIds.contains(l.id)).length;
    return done / lessons.length;
  }

  List<Course> myEnrolledCourses() {
    final uid = currentUser?.id;
    final ids =
        enrollments.where((e) => e.studentId == uid).map((e) => e.courseId);
    return courses.where((c) => ids.contains(c.id)).toList();
  }

  // ── v2: 1v1 bookings ───────────────────────────────────

  Future<TutorBooking> requestBooking({
    required String tutorId,
    required String tutorName,
    required DateTime startsAtUtc,
    required int durationMin,
    String meetingLink = '',
    String note = '',
  }) async {
    final me = currentUser!;
    final b = TutorBooking(
      id: newId(),
      tutorId: tutorId,
      tutorName: tutorName,
      studentId: me.id,
      studentName: me.displayName,
      startsAtUtc: startsAtUtc,
      durationMin: durationMin,
      meetingLink: meetingLink,
      note: note,
    );
    bookings.add(b);
    _mutate();
    return b;
  }

  TutorBooking? bookingById(String id) {
    for (final b in bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<TutorBooking> myBookings() {
    final uid = currentUser?.id;
    final list =
        bookings.where((b) => b.studentId == uid).toList()
          ..sort((a, b) {
            final at = a.startsAtUtc, bt = b.startsAtUtc;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return at.compareTo(bt);
          });
    return list;
  }

  Future<void> setBookingStatus(String id, String status) async {
    final b = bookingById(id);
    if (b == null) return;
    b.status = status;
    if (status == 'completed') {
      // completedAt is implied by status; keep the record.
    }
    _mutate();
  }

  Future<void> leaveBookingReview(
    String id, {
    required double rating,
    required String text,
  }) async {
    final b = bookingById(id);
    if (b == null) return;
    b.reviewRating = rating;
    b.reviewText = text.trim();
    _mutate();
  }

  // ── v2: live sessions & quizzes ────────────────────────

  List<LiveSession> visibleLiveSessions() {
    final list = liveSessions.toList()
      ..sort((a, b) {
        int rank(String s) =>
            s == 'live' ? 0 : (s == 'scheduled' ? 1 : 2);
        final r = rank(a.status) - rank(b.status);
        if (r != 0) return r;
        final at = a.startsAtUtc, bt = b.startsAtUtc;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });
    return list;
  }

  LiveSession? liveSessionById(String id) {
    for (final s in liveSessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<LiveSession> createLiveSession(LiveSession draft) async {
    liveSessions.add(draft);
    _mutate();
    return draft;
  }

  Future<void> updateLiveSession(LiveSession updated) async {
    final i = liveSessions.indexWhere((s) => s.id == updated.id);
    if (i >= 0) {
      liveSessions[i] = updated;
      _mutate();
    }
  }

  Future<void> setLiveStatus(String id, String status) async {
    final s = liveSessionById(id);
    if (s == null) return;
    s.status = status;
    _mutate();
  }

  Future<void> submitQuizAttempt(QuizAttempt attempt) async {
    quizAttempts.add(attempt);
    _mutate();
  }

  List<QuizAttempt> attemptsFor(String sessionId) {
    final list = quizAttempts
        .where((a) => a.sessionId == sessionId)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  // ── v2: messaging (demo-mode, on-device) ───────────────

  List<Conversation> myConversations() {
    final uid = currentUser?.id;
    final list = conversations
        .where((c) => c.participantIds.contains(uid))
        .toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return list;
  }

  Conversation conversationWith(String otherUserId) {
    final uid = currentUser?.id ?? '';
    for (final c in conversations) {
      final p = c.participantIds;
      if (p.length == 2 && p.contains(uid) && p.contains(otherUserId)) {
        return c;
      }
    }
    final other = displayNameFor(otherUserId);
    final c = Conversation(
      id: newId(),
      participantIds: [uid, otherUserId],
      title: other,
    );
    conversations.add(c);
    _mutate();
    return c;
  }

  List<ChatMessage> messagesFor(String conversationId) {
    final list = chatMessages
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<ChatMessage> sendMessage(
    String conversationId, {
    String body = '',
    String? imagePath,
  }) async {
    final me = currentUser!;
    final m = ChatMessage(
      id: newId(),
      conversationId: conversationId,
      senderId: me.id,
      senderName: me.displayName,
      body: body.trim(),
      imagePath: imagePath,
    );
    chatMessages.add(m);
    for (final c in conversations) {
      if (c.id == conversationId) {
        c.lastMessageAt = DateTime.now();
        break;
      }
    }
    _mutate();
    return m;
  }

  Future<void> deleteConversation(String id) async {
    conversations.removeWhere((c) => c.id == id);
    chatMessages.removeWhere((m) => m.conversationId == id);
    _mutate();
  }

  /// Best-effort display name for any id (users first, then demo tutors).
  String displayNameFor(String id) {
    final u = _userById(id);
    if (u != null) return u.displayName;
    for (final t in tutors) {
      if (t.id == id) return t.name;
    }
    return 'Lurniq user';
  }

  String? avatarFor(String id) {
    final u = _userById(id);
    return u?.avatarPath;
  }
}

/// Theme preference. Stored on the user as a string for JSON compatibility.
enum ThemeModeSetting { system, light, dark }
}
