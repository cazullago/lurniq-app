/// Lurniq data models. All models serialize to plain JSON maps so the
/// on-device store (and later Firestore documents) stay schema-compatible.
library;

List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

Map<String, String> _strMap(dynamic v) => v is Map
    ? v.map((k, e) => MapEntry(k.toString(), e.toString()))
    : <String, String>{};

DateTime _dt(dynamic v, DateTime fallback) {
  if (v is String) return DateTime.tryParse(v) ?? fallback;
  return fallback;
}

// ── User ─────────────────────────────────────────────────

class AppUser {
  AppUser({
    required this.id,
    required this.displayName,
    required this.username,
    this.email,
    this.avatarPath,
    this.bio = '',
    this.country = '',
    this.language = 'en',
    this.educationLevel = '',
    this.school = '',
    List<String>? interests,
    List<String>? learningGoals,
    this.currency = 'USD',
    this.timezoneMode = 'device',
    this.timezoneOffsetMinutes = 0,
    this.timezoneLabel = '',
    this.notifPush = true,
    this.notifLikes = true,
    this.notifComments = true,
    this.notifReminders = true,
    this.notifGroups = true,
    Map<String, String>? fieldPrivacy,
    List<String>? followingIds,
    List<String>? blockedIds,
    DateTime? createdAt,
    this.demoSeed = false,
  })  : interests = interests ?? [],
        learningGoals = learningGoals ?? [],
        fieldPrivacy = fieldPrivacy ?? {},
        followingIds = followingIds ?? [],
        blockedIds = blockedIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  String id;
  String displayName;
  String username;
  String? email;
  String? avatarPath;
  String bio;
  String country;
  String language;
  String educationLevel;
  String school;
  List<String> interests;
  List<String> learningGoals;
  String currency;
  String timezoneMode; // 'device' | 'fixed'
  int timezoneOffsetMinutes;
  String timezoneLabel;
  bool notifPush;
  bool notifLikes;
  bool notifComments;
  bool notifReminders;
  bool notifGroups;
  Map<String, String> fieldPrivacy; // field -> public|followers|private
  List<String> followingIds;
  List<String> blockedIds;
  DateTime createdAt;
  bool demoSeed;

  /// Privacy for a profile field; defaults to public.
  String privacyFor(String field) => fieldPrivacy[field] ?? 'public';

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'username': username,
        'email': email,
        'avatarPath': avatarPath,
        'bio': bio,
        'country': country,
        'language': language,
        'educationLevel': educationLevel,
        'school': school,
        'interests': interests,
        'learningGoals': learningGoals,
        'currency': currency,
        'timezoneMode': timezoneMode,
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
        'timezoneLabel': timezoneLabel,
        'notifPush': notifPush,
        'notifLikes': notifLikes,
        'notifComments': notifComments,
        'notifReminders': notifReminders,
        'notifGroups': notifGroups,
        'fieldPrivacy': fieldPrivacy,
        'followingIds': followingIds,
        'blockedIds': blockedIds,
        'createdAt': createdAt.toIso8601String(),
        'demoSeed': demoSeed,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        displayName: (j['displayName'] ?? '') as String,
        username: (j['username'] ?? '') as String,
        email: j['email'] as String?,
        avatarPath: j['avatarPath'] as String?,
        bio: (j['bio'] ?? '') as String,
        country: (j['country'] ?? '') as String,
        language: (j['language'] ?? 'en') as String,
        educationLevel: (j['educationLevel'] ?? '') as String,
        school: (j['school'] ?? '') as String,
        interests: _strList(j['interests']),
        learningGoals: _strList(j['learningGoals']),
        currency: (j['currency'] ?? 'USD') as String,
        timezoneMode: (j['timezoneMode'] ?? 'device') as String,
        timezoneOffsetMinutes: (j['timezoneOffsetMinutes'] ?? 0) as int,
        timezoneLabel: (j['timezoneLabel'] ?? '') as String,
        notifPush: (j['notifPush'] ?? true) as bool,
        notifLikes: (j['notifLikes'] ?? true) as bool,
        notifComments: (j['notifComments'] ?? true) as bool,
        notifReminders: (j['notifReminders'] ?? true) as bool,
        notifGroups: (j['notifGroups'] ?? true) as bool,
        fieldPrivacy: _strMap(j['fieldPrivacy']),
        followingIds: _strList(j['followingIds']),
        blockedIds: _strList(j['blockedIds']),
        createdAt: _dt(j['createdAt'], DateTime.now()),
        demoSeed: (j['demoSeed'] ?? false) as bool,
      );
}

// ── Feed ─────────────────────────────────────────────────

class Post {
  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.type = 'discussion',
    this.title = '',
    this.body = '',
    this.subject = '',
    this.level = '',
    List<String>? tags,
    List<String>? imagePaths,
    this.linkUrl,
    this.linkLabel,
    this.resourceKind,
    this.freeAccess = true,
    this.accessNote = '',
    List<String>? likes,
    List<String>? bookmarks,
    this.resolved = false,
    this.helpfulCommentId,
    this.hidden = false,
    // study group fields (type == 'studyGroup'); times stored in UTC
    this.groupStartsAtUtc,
    this.groupDurationMin,
    this.groupMaxParticipants,
    this.groupFormat,
    this.groupLink,
    this.groupLocation,
    List<String>? participantIds,
    List<String>? pendingIds,
    this.groupCancelled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDemo = false,
  })  : tags = tags ?? [],
        imagePaths = imagePaths ?? [],
        likes = likes ?? [],
        bookmarks = bookmarks ?? [],
        participantIds = participantIds ?? [],
        pendingIds = pendingIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String id;
  String authorId;
  String authorName;
  String? authorAvatar;
  String type;
  String title;
  String body;
  String subject;
  String level;
  List<String> tags;
  List<String> imagePaths;
  String? linkUrl;
  String? linkLabel;
  String? resourceKind;
  bool freeAccess;
  String accessNote;
  List<String> likes;
  List<String> bookmarks;
  bool resolved;
  String? helpfulCommentId;
  bool hidden;
  DateTime? groupStartsAtUtc;
  int? groupDurationMin;
  int? groupMaxParticipants;
  String? groupFormat; // online | inPerson
  String? groupLink;
  String? groupLocation;
  List<String> participantIds;
  List<String> pendingIds;
  bool groupCancelled;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDemo;

  int get spotsLeft {
    final max = groupMaxParticipants;
    if (max == null || max <= 0) return 999;
    final left = max - participantIds.length;
    return left < 0 ? 0 : left;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'type': type,
        'title': title,
        'body': body,
        'subject': subject,
        'level': level,
        'tags': tags,
        'imagePaths': imagePaths,
        'linkUrl': linkUrl,
        'linkLabel': linkLabel,
        'resourceKind': resourceKind,
        'freeAccess': freeAccess,
        'accessNote': accessNote,
        'likes': likes,
        'bookmarks': bookmarks,
        'resolved': resolved,
        'helpfulCommentId': helpfulCommentId,
        'hidden': hidden,
        'groupStartsAtUtc': groupStartsAtUtc?.toIso8601String(),
        'groupDurationMin': groupDurationMin,
        'groupMaxParticipants': groupMaxParticipants,
        'groupFormat': groupFormat,
        'groupLink': groupLink,
        'groupLocation': groupLocation,
        'participantIds': participantIds,
        'pendingIds': pendingIds,
        'groupCancelled': groupCancelled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDemo': isDemo,
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        authorId: (j['authorId'] ?? '') as String,
        authorName: (j['authorName'] ?? '') as String,
        authorAvatar: j['authorAvatar'] as String?,
        type: (j['type'] ?? 'discussion') as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        subject: (j['subject'] ?? '') as String,
        level: (j['level'] ?? '') as String,
        tags: _strList(j['tags']),
        imagePaths: _strList(j['imagePaths']),
        linkUrl: j['linkUrl'] as String?,
        linkLabel: j['linkLabel'] as String?,
        resourceKind: j['resourceKind'] as String?,
        freeAccess: (j['freeAccess'] ?? true) as bool,
        accessNote: (j['accessNote'] ?? '') as String,
        likes: _strList(j['likes']),
        bookmarks: _strList(j['bookmarks']),
        resolved: (j['resolved'] ?? false) as bool,
        helpfulCommentId: j['helpfulCommentId'] as String?,
        hidden: (j['hidden'] ?? false) as bool,
        groupStartsAtUtc: j['groupStartsAtUtc'] is String
            ? DateTime.tryParse(j['groupStartsAtUtc'] as String)
            : null,
        groupDurationMin: (j['groupDurationMin'] as num?)?.toInt(),
        groupMaxParticipants: (j['groupMaxParticipants'] as num?)?.toInt(),
        groupFormat: j['groupFormat'] as String?,
        groupLink: j['groupLink'] as String?,
        groupLocation: j['groupLocation'] as String?,
        participantIds: _strList(j['participantIds']),
        pendingIds: _strList(j['pendingIds']),
        groupCancelled: (j['groupCancelled'] ?? false) as bool,
        createdAt: _dt(j['createdAt'], DateTime.now()),
        updatedAt: _dt(j['updatedAt'], DateTime.now()),
        isDemo: (j['isDemo'] ?? false) as bool,
      );
}

class FeedComment {
  FeedComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.body = '',
    this.parentId,
    List<String>? likes,
    this.isHelpful = false,
    DateTime? createdAt,
    this.isDemo = false,
  })  : likes = likes ?? [],
        createdAt = createdAt ?? DateTime.now();

  String id;
  String postId;
  String authorId;
  String authorName;
  String body;
  String? parentId; // null = top-level comment
  List<String> likes;
  bool isHelpful;
  DateTime createdAt;
  bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'body': body,
        'parentId': parentId,
        'likes': likes,
        'isHelpful': isHelpful,
        'createdAt': createdAt.toIso8601String(),
        'isDemo': isDemo,
      };

  factory FeedComment.fromJson(Map<String, dynamic> j) => FeedComment(
        id: j['id'] as String,
        postId: (j['postId'] ?? '') as String,
        authorId: (j['authorId'] ?? '') as String,
        authorName: (j['authorName'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        parentId: j['parentId'] as String?,
        likes: _strList(j['likes']),
        isHelpful: (j['isHelpful'] ?? false) as bool,
        createdAt: _dt(j['createdAt'], DateTime.now()),
        isDemo: (j['isDemo'] ?? false) as bool,
      );
}

// ── Tutors (Phase 1: seeded demo directory, read-only) ───

class Tutor {
  Tutor({
    required this.id,
    required this.name,
    required this.initials,
    required this.colorValue,
    this.intro = '',
    List<String>? subjects,
    List<String>? levels,
    this.country = '',
    List<String>? languages,
    this.priceUsd = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.availability = '',
    this.experience = '',
    this.qualifications,
    this.verification = 'unverified',
    this.onlineNow = false,
    this.isDemo = true,
  })  : subjects = subjects ?? [],
        levels = levels ?? [],
        languages = languages ?? [];

  String id;
  String name;
  String initials;
  int colorValue;
  String intro;
  List<String> subjects;
  List<String> levels;
  String country;
  List<String> languages;
  double priceUsd; // 0 = free
  double rating;
  int reviewCount;
  String availability;
  String experience;
  String? qualifications;
  /// 'unverified' | 'id' | 'credential' — always labeled honestly in the UI.
  String verification;
  bool onlineNow;
  bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'colorValue': colorValue,
        'intro': intro,
        'subjects': subjects,
        'levels': levels,
        'country': country,
        'languages': languages,
        'priceUsd': priceUsd,
        'rating': rating,
        'reviewCount': reviewCount,
        'availability': availability,
        'experience': experience,
        'qualifications': qualifications,
        'verification': verification,
        'onlineNow': onlineNow,
        'isDemo': isDemo,
      };

  factory Tutor.fromJson(Map<String, dynamic> j) => Tutor(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        initials: (j['initials'] ?? '') as String,
        colorValue: (j['colorValue'] ?? 0xFF0F766E) as int,
        intro: (j['intro'] ?? '') as String,
        subjects: _strList(j['subjects']),
        levels: _strList(j['levels']),
        country: (j['country'] ?? '') as String,
        languages: _strList(j['languages']),
        priceUsd: ((j['priceUsd'] ?? 0) as num).toDouble(),
        rating: ((j['rating'] ?? 0) as num).toDouble(),
        reviewCount: (j['reviewCount'] ?? 0) as int,
        availability: (j['availability'] ?? '') as String,
        experience: (j['experience'] ?? '') as String,
        qualifications: j['qualifications'] as String?,
        verification: (j['verification'] ?? 'unverified') as String,
        onlineNow: (j['onlineNow'] ?? false) as bool,
        isDemo: (j['isDemo'] ?? true) as bool,
      );
}

class TutorReview {
  TutorReview({
    required this.id,
    required this.tutorId,
    required this.authorName,
    this.rating = 5,
    this.text = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String tutorId;
  String authorName;
  double rating;
  String text;
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tutorId': tutorId,
        'authorName': authorName,
        'rating': rating,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TutorReview.fromJson(Map<String, dynamic> j) => TutorReview(
        id: j['id'] as String,
        tutorId: (j['tutorId'] ?? '') as String,
        authorName: (j['authorName'] ?? '') as String,
        rating: ((j['rating'] ?? 5) as num).toDouble(),
        text: (j['text'] ?? '') as String,
        createdAt: _dt(j['createdAt'], DateTime.now()),
      );
}

/// Someone who asked to be notified when tutor applications open (Phase 3).
class TutorInterest {
  TutorInterest({
    required this.id,
    this.name = '',
    this.contact = '',
    this.subjects = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String name;
  String contact;
  String subjects;
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contact': contact,
        'subjects': subjects,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TutorInterest.fromJson(Map<String, dynamic> j) => TutorInterest(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        contact: (j['contact'] ?? '') as String,
        subjects: (j['subjects'] ?? '') as String,
        createdAt: _dt(j['createdAt'], DateTime.now()),
      );
}

// ── Planner ──────────────────────────────────────────────

class SubjectFolder {
  SubjectFolder({
    required this.id,
    required this.ownerId,
    this.name = '',
    this.colorValue = 0xFF0F766E,
    this.icon = 'book',
    this.order = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String ownerId;
  String name;
  int colorValue;
  String icon;
  int order;
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'colorValue': colorValue,
        'icon': icon,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SubjectFolder.fromJson(Map<String, dynamic> j) => SubjectFolder(
        id: j['id'] as String,
        ownerId: (j['ownerId'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        colorValue: (j['colorValue'] ?? 0xFF0F766E) as int,
        icon: (j['icon'] ?? 'book') as String,
        order: (j['order'] ?? 0) as int,
        createdAt: _dt(j['createdAt'], DateTime.now()),
      );
}

class Lesson {
  Lesson({
    required this.id,
    required this.ownerId,
    required this.folderId,
    this.title = '',
    this.photoPath = '',
    this.notes = '',
    List<String>? tags,
    DateTime? lessonDate,
    DateTime? createdAt,
    // Phase 2: extractedText (OCR) will be added here.
  })  : tags = tags ?? [],
        lessonDate = lessonDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  String id;
  String ownerId;
  String folderId;
  String title;
  String photoPath;
  String notes;
  List<String> tags;
  DateTime lessonDate;
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'folderId': folderId,
        'title': title,
        'photoPath': photoPath,
        'notes': notes,
        'tags': tags,
        'lessonDate': lessonDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        ownerId: (j['ownerId'] ?? '') as String,
        folderId: (j['folderId'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        photoPath: (j['photoPath'] ?? '') as String,
        notes: (j['notes'] ?? '') as String,
        tags: _strList(j['tags']),
        lessonDate: _dt(j['lessonDate'], DateTime.now()),
        createdAt: _dt(j['createdAt'], DateTime.now()),
      );
}

class StudyTask {
  StudyTask({
    required this.id,
    required this.ownerId,
    this.title = '',
    this.folderId,
    this.instructions = '',
    this.dueAtLocal,
    this.priority = 'medium',
    this.status = 'todo',
    this.notes = '',
    this.photoPath,
    this.reminder = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String ownerId;
  String title;
  String? folderId; // subject
  String instructions;
  DateTime? dueAtLocal; // viewer's wall-clock time
  String priority; // low|medium|high
  String status; // todo|doing|done
  String notes;
  String? photoPath; // attached assignment photo (Phase 2 reads it)
  bool reminder; // push delivery arrives in Phase 2; the time is saved now
  DateTime createdAt;
  DateTime? completedAt;

  bool get isDone => status == 'done';

  bool get isOverdue {
    if (isDone || dueAtLocal == null) return false;
    return dueAtLocal!.isBefore(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'folderId': folderId,
        'instructions': instructions,
        'dueAtLocal': dueAtLocal?.toIso8601String(),
        'priority': priority,
        'status': status,
        'notes': notes,
        'photoPath': photoPath,
        'reminder': reminder,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory StudyTask.fromJson(Map<String, dynamic> j) => StudyTask(
        id: j['id'] as String,
        ownerId: (j['ownerId'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        folderId: j['folderId'] as String?,
        instructions: (j['instructions'] ?? '') as String,
        dueAtLocal: j['dueAtLocal'] is String
            ? DateTime.tryParse(j['dueAtLocal'] as String)
            : null,
        priority: (j['priority'] ?? 'medium') as String,
        status: (j['status'] ?? 'todo') as String,
        notes: (j['notes'] ?? '') as String,
        photoPath: j['photoPath'] as String?,
        reminder: (j['reminder'] ?? false) as bool,
        createdAt: _dt(j['createdAt'], DateTime.now()),
        completedAt: j['completedAt'] is String
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
      );
}

// ── Moderation & admin ───────────────────────────────────

class Report {
  Report({
    required this.id,
    this.targetType = 'post',
    this.targetId = '',
    this.targetSummary = '',
    this.reporterId = '',
    this.reason = '',
    this.status = 'open',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String targetType; // post | comment | user
  String targetId;
  String targetSummary;
  String reporterId;
  String reason;
  String status; // open | dismissed | actioned
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetType': targetType,
        'targetId': targetId,
        'targetSummary': targetSummary,
        'reporterId': reporterId,
        'reason': reason,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Report.fromJson(Map<String, dynamic> j) => Report(
        id: j['id'] as String,
        targetType: (j['targetType'] ?? 'post') as String,
        targetId: (j['targetId'] ?? '') as String,
        targetSummary: (j['targetSummary'] ?? '') as String,
        reporterId: (j['reporterId'] ?? '') as String,
        reason: (j['reason'] ?? '') as String,
        status: (j['status'] ?? 'open') as String,
        createdAt: _dt(j['createdAt'], DateTime.now()),
      );
}

class AdminLogEntry {
  AdminLogEntry({
    required this.id,
    DateTime? at,
    this.action = '',
    this.detail = '',
  }) : at = at ?? DateTime.now();

  String id;
  DateTime at;
  String action;
  String detail;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'action': action,
        'detail': detail,
      };

  factory AdminLogEntry.fromJson(Map<String, dynamic> j) => AdminLogEntry(
        id: j['id'] as String,
        at: _dt(j['at'], DateTime.now()),
        action: (j['action'] ?? '') as String,
        detail: (j['detail'] ?? '') as String,
      );
}

class Announcement {
  Announcement({
    required this.id,
    this.title = '',
    this.body = '',
    DateTime? createdAt,
    this.active = true,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String title;
  String body;
  DateTime createdAt;
  bool active;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'active': active,
      };

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        createdAt: _dt(j['createdAt'], DateTime.now()),
        active: (j['active'] ?? true) as bool,
      );
}
