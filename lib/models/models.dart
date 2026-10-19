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
    this.themeMode = 'system',
    this.tosVersion = '',
    this.tosAcceptedAt,
    this.ppVersion = '',
    this.ppAcceptedAt,
    this.tutorAgreementVersion = '',
    this.tutorAgreementAt,
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
  /// 'system' | 'light' | 'dark' — manual day/night override.
  String themeMode;
  // Legal acceptance (ToS + Privacy Policy at sign-up; Tutor Agreement
  // before listing). Version + timestamp are stored with the account.
  String tosVersion;
  DateTime? tosAcceptedAt;
  String ppVersion;
  DateTime? ppAcceptedAt;
  String tutorAgreementVersion;
  DateTime? tutorAgreementAt;

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
        'themeMode': themeMode,
        'tosVersion': tosVersion,
        'tosAcceptedAt': tosAcceptedAt?.toIso8601String(),
        'ppVersion': ppVersion,
        'ppAcceptedAt': ppAcceptedAt?.toIso8601String(),
        'tutorAgreementVersion': tutorAgreementVersion,
        'tutorAgreementAt': tutorAgreementAt?.toIso8601String(),
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
        themeMode: (j['themeMode'] ?? 'system') as String,
        tosVersion: (j['tosVersion'] ?? '') as String,
        tosAcceptedAt: j['tosAcceptedAt'] is String
            ? DateTime.tryParse(j['tosAcceptedAt'] as String)
            : null,
        ppVersion: (j['ppVersion'] ?? '') as String,
        ppAcceptedAt: j['ppAcceptedAt'] is String
            ? DateTime.tryParse(j['ppAcceptedAt'] as String)
            : null,
        tutorAgreementVersion:
            (j['tutorAgreementVersion'] ?? '') as String,
        tutorAgreementAt: j['tutorAgreementAt'] is String
            ? DateTime.tryParse(j['tutorAgreementAt'] as String)
            : null,
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
    this.taskType = 'assignment',
    this.taskTypeCustom = '',
    this.gradeScore = '',
    this.gradeNote = '',
    this.gradePhotoPath,
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
  /// assignment|activity|project|quiz|exam|thesis|performance|other
  String taskType;
  /// free text when taskType == 'other'
  String taskTypeCustom;
  /// grade logged on a done task: typed score (e.g. "95/100")
  String gradeScore;
  String gradeNote;
  String? gradePhotoPath;

  bool get isDone => status == 'done';

  String get typeLabel =>
      taskType == 'other' && taskTypeCustom.isNotEmpty ? taskTypeCustom : taskType;

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
        'taskType': taskType,
        'taskTypeCustom': taskTypeCustom,
        'gradeScore': gradeScore,
        'gradeNote': gradeNote,
        'gradePhotoPath': gradePhotoPath,
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
        taskType: (j['taskType'] ?? 'assignment') as String,
        taskTypeCustom: (j['taskTypeCustom'] ?? '') as String,
        gradeScore: (j['gradeScore'] ?? '') as String,
        gradeNote: (j['gradeNote'] ?? '') as String,
        gradePhotoPath: j['gradePhotoPath'] as String?,
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

// ── v2: Courses (pre-made tutor lessons) ──────────────────

class Course {
  Course({
    required this.id,
    required this.tutorId,
    this.tutorName = '',
    this.title = '',
    this.description = '',
    this.subject = '',
    this.level = '',
    this.thumbnailPath,
    this.priceUsd = 0,
    this.published = true,
    this.rating = 0,
    this.reviewCount = 0,
    this.enrollmentCount = 0,
    DateTime? createdAt,
    this.isDemo = false,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String tutorId;
  String tutorName;
  String title;
  String description;
  String subject;
  String level;
  String? thumbnailPath;
  double priceUsd; // 0 = free
  bool published;
  double rating;
  int reviewCount;
  int enrollmentCount;
  DateTime createdAt;
  bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tutorId': tutorId,
        'tutorName': tutorName,
        'title': title,
        'description': description,
        'subject': subject,
        'level': level,
        'thumbnailPath': thumbnailPath,
        'priceUsd': priceUsd,
        'published': published,
        'rating': rating,
        'reviewCount': reviewCount,
        'enrollmentCount': enrollmentCount,
        'createdAt': createdAt.toIso8601String(),
        'isDemo': isDemo,
      };

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'] as String,
        tutorId: (j['tutorId'] ?? '') as String,
        tutorName: (j['tutorName'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        subject: (j['subject'] ?? '') as String,
        level: (j['level'] ?? '') as String,
        thumbnailPath: j['thumbnailPath'] as String?,
        priceUsd: ((j['priceUsd'] ?? 0) as num).toDouble(),
        published: (j['published'] ?? true) as bool,
        rating: ((j['rating'] ?? 0) as num).toDouble(),
        reviewCount: (j['reviewCount'] ?? 0) as int,
        enrollmentCount: (j['enrollmentCount'] ?? 0) as int,
        createdAt: _dt(j['createdAt'], DateTime.now()),
        isDemo: (j['isDemo'] ?? false) as bool,
      );
}

class CourseLesson {
  CourseLesson({
    required this.id,
    required this.courseId,
    this.title = '',
    this.kind = 'text', // video | slides | text
    this.videoUrl = '',
    this.body = '',
    this.durationMin = 0,
    this.order = 0,
  });

  String id;
  String courseId;
  String title;
  String kind;
  String videoUrl;
  String body;
  int durationMin;
  int order;

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'kind': kind,
        'videoUrl': videoUrl,
        'body': body,
        'durationMin': durationMin,
        'order': order,
      };

  factory CourseLesson.fromJson(Map<String, dynamic> j) => CourseLesson(
        id: j['id'] as String,
        courseId: (j['courseId'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        kind: (j['kind'] ?? 'text') as String,
        videoUrl: (j['videoUrl'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        durationMin: (j['durationMin'] ?? 0) as int,
        order: (j['order'] ?? 0) as int,
      );
}

class CourseEnrollment {
  CourseEnrollment({
    required this.id,
    required this.courseId,
    required this.studentId,
    List<String>? doneLessonIds,
    DateTime? enrolledAt,
  })  : doneLessonIds = doneLessonIds ?? [],
        enrolledAt = enrolledAt ?? DateTime.now();

  String id;
  String courseId;
  String studentId;
  List<String> doneLessonIds;
  DateTime enrolledAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'studentId': studentId,
        'doneLessonIds': doneLessonIds,
        'enrolledAt': enrolledAt.toIso8601String(),
      };

  factory CourseEnrollment.fromJson(Map<String, dynamic> j) =>
      CourseEnrollment(
        id: j['id'] as String,
        courseId: (j['courseId'] ?? '') as String,
        studentId: (j['studentId'] ?? '') as String,
        doneLessonIds: _strList(j['doneLessonIds']),
        enrolledAt: _dt(j['enrolledAt'], DateTime.now()),
      );
}

// ── v2: 1v1 tutoring bookings ────────────────────────────

class TutorBooking {
  TutorBooking({
    required this.id,
    required this.tutorId,
    this.tutorName = '',
    required this.studentId,
    this.studentName = '',
    this.startsAtUtc,
    this.durationMin = 60,
    this.meetingLink = '',
    this.note = '',
    this.status = 'pending', // pending|accepted|declined|completed|cancelled
    this.reviewRating = 0,
    this.reviewText = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String tutorId;
  String tutorName;
  String studentId;
  String studentName;
  DateTime? startsAtUtc;
  int durationMin;
  String meetingLink;
  String note;
  String status;
  double reviewRating;
  String reviewText;
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tutorId': tutorId,
        'tutorName': tutorName,
        'studentId': studentId,
        'studentName': studentName,
        'startsAtUtc': startsAtUtc?.toIso8601String(),
        'durationMin': durationMin,
        'meetingLink': meetingLink,
        'note': note,
        'status': status,
        'reviewRating': reviewRating,
        'reviewText': reviewText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TutorBooking.fromJson(Map<String, dynamic> j) => TutorBooking(
        id: j['id'] as String,
        tutorId: (j['tutorId'] ?? '') as String,
        tutorName: (j['tutorName'] ?? '') as String,
        studentId: (j['studentId'] ?? '') as String,
        studentName: (j['studentName'] ?? '') as String,
        startsAtUtc: j['startsAtUtc'] is String
            ? DateTime.tryParse(j['startsAtUtc'] as String)
            : null,
        durationMin: (j['durationMin'] ?? 60) as int,
        meetingLink: (j['meetingLink'] ?? '') as String,
        note: (j['note'] ?? '') as String,
        status: (j['status'] ?? 'pending') as String,
        reviewRating: ((j['reviewRating'] ?? 0) as num).toDouble(),
        reviewText: (j['reviewText'] ?? '') as String,
        createdAt: _dt(j['createdAt'], DateTime.now()),
      );
}

// ── v2: Live sessions + in-app quizzes ───────────────────

class QuizQuestion {
  QuizQuestion({
    required this.id,
    this.question = '',
    List<String>? options,
    this.correctIndex = 0,
    this.secondsPerQuestion = 30,
  }) : options = options ?? [];

  String id;
  String question;
  List<String> options;
  int correctIndex;
  int secondsPerQuestion;

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'secondsPerQuestion': secondsPerQuestion,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        question: (j['question'] ?? '') as String,
        options: _strList(j['options']),
        correctIndex: (j['correctIndex'] ?? 0) as int,
        secondsPerQuestion: (j['secondsPerQuestion'] ?? 30) as int,
      );
}

class LiveSession {
  LiveSession({
    required this.id,
    required this.tutorId,
    this.tutorName = '',
    this.title = '',
    this.subject = '',
    this.description = '',
    this.startsAtUtc,
    this.durationMin = 60,
    this.meetingLink = '',
    this.status = 'scheduled', // scheduled|live|ended
    List<QuizQuestion>? quiz,
    DateTime? createdAt,
    this.isDemo = false,
  })  : quiz = quiz ?? [],
        createdAt = createdAt ?? DateTime.now();

  String id;
  String tutorId;
  String tutorName;
  String title;
  String subject;
  String description;
  DateTime? startsAtUtc;
  int durationMin;
  String meetingLink;
  String status;
  List<QuizQuestion> quiz;
  DateTime createdAt;
  bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tutorId': tutorId,
        'tutorName': tutorName,
        'title': title,
        'subject': subject,
        'description': description,
        'startsAtUtc': startsAtUtc?.toIso8601String(),
        'durationMin': durationMin,
        'meetingLink': meetingLink,
        'status': status,
        'quiz': quiz.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isDemo': isDemo,
      };

  factory LiveSession.fromJson(Map<String, dynamic> j) => LiveSession(
        id: j['id'] as String,
        tutorId: (j['tutorId'] ?? '') as String,
        tutorName: (j['tutorName'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        subject: (j['subject'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        startsAtUtc: j['startsAtUtc'] is String
            ? DateTime.tryParse(j['startsAtUtc'] as String)
            : null,
        durationMin: (j['durationMin'] ?? 60) as int,
        meetingLink: (j['meetingLink'] ?? '') as String,
        status: (j['status'] ?? 'scheduled') as String,
        quiz: ((j['quiz'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(QuizQuestion.fromJson)
            .toList(),
        createdAt: _dt(j['createdAt'], DateTime.now()),
        isDemo: (j['isDemo'] ?? false) as bool,
      );
}

class QuizAttempt {
  QuizAttempt({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.userName = '',
    this.score = 0,
    this.total = 0,
    DateTime? answeredAt,
    this.isDemo = false,
  }) : answeredAt = answeredAt ?? DateTime.now();

  String id;
  String sessionId;
  String userId;
  String userName;
  int score;
  int total;
  DateTime answeredAt;
  bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'userId': userId,
        'userName': userName,
        'score': score,
        'total': total,
        'answeredAt': answeredAt.toIso8601String(),
        'isDemo': isDemo,
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
        id: j['id'] as String,
        sessionId: (j['sessionId'] ?? '') as String,
        userId: (j['userId'] ?? '') as String,
        userName: (j['userName'] ?? '') as String,
        score: (j['score'] ?? 0) as int,
        total: (j['total'] ?? 0) as int,
        answeredAt: _dt(j['answeredAt'], DateTime.now()),
        isDemo: (j['isDemo'] ?? false) as bool,
      );
}

// ── v2: Messaging (demo-mode, on-device) ─────────────────

class Conversation {
  Conversation({
    required this.id,
    List<String>? participantIds,
    this.title = '',
    DateTime? lastMessageAt,
    this.isDemo = false,
  })  : participantIds = participantIds ?? [],
        lastMessageAt = lastMessageAt ?? DateTime.now();

  String id;
  List<String> participantIds;
  String title;
  DateTime lastMessageAt;
  bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'title': title,
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'isDemo': isDemo,
      };

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as String,
        participantIds: _strList(j['participantIds']),
        title: (j['title'] ?? '') as String,
        lastMessageAt: _dt(j['lastMessageAt'], DateTime.now()),
        isDemo: (j['isDemo'] ?? false) as bool,
      );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName = '',
    this.body = '',
    this.imagePath,
    DateTime? createdAt,
    this.isDemo = false,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String conversationId;
  String senderId;
  String senderName;
  String body;
  String? imagePath;
  DateTime createdAt;
  bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'body': body,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'isDemo': isDemo,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        conversationId: (j['conversationId'] ?? '') as String,
        senderId: (j['senderId'] ?? '') as String,
        senderName: (j['senderName'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        imagePath: j['imagePath'] as String?,
        createdAt: _dt(j['createdAt'], DateTime.now()),
        isDemo: (j['isDemo'] ?? false) as bool,
      );
}

// ── v2: Lurniq Plus subscription ─────────────────────────
//
// Pricing catalog. PHP is the base currency; USD figures are approximate
// equivalents for display (rate noted next to the price in the UI).
class PlusCatalog {
  static const String baseCurrency = 'PHP';
  static const double usdPerPhp = 1 / 58; // approximate, display only

  static const double monthlyPhp = 149;
  static const double yearlyPhp = 999;

  static String php(double v) => '₱${v.toStringAsFixed(0)}';

  static String usdApprox(double phpPrice) =>
      '≈ \$${(phpPrice * usdPerPhp).toStringAsFixed(2)}';

  /// "₱149/month (≈ $2.57)" or "$2.57/month (≈ ₱149)" depending on preference.
  static String priceLine(num phpPrice, String per, String currencyPref) {
    final amount = phpPrice.toDouble();
    final phpStr = '${php(amount)}/$per';
    final usd = '\$${(amount * usdPerPhp).toStringAsFixed(2)}/$per';
    if (currencyPref == 'USD') return '$usd (≈ $phpStr)';
    return '$phpStr (${usdApprox(amount)}/$per)';
  }
}

// ── v2: Lurniq Plus subscription entitlement ─────────────
//
// Honesty contract: real charging requires Google Play Billing, which is NOT
// wired (needs the user's Play Console account — see README "Payments").
// Subscribe buttons are marked "Coming soon" and move no money. When Play
// Billing lands, it only needs to call AppStore.setEntitlement() with
// source 'play_billing' — no refactoring of call sites.
class Entitlement {
  Entitlement({
    this.plan = 'free', // free | plus
    this.source = 'none', // none | demo | play_billing
    this.plusExpiresAt,
  });

  String plan;
  String source;
  DateTime? plusExpiresAt;

  bool get isPlus {
    if (plan != 'plus') return false;
    final exp = plusExpiresAt;
    return exp == null || exp.isAfter(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'source': source,
        'plusExpiresAt': plusExpiresAt?.toIso8601String(),
      };

  factory Entitlement.fromJson(Map<String, dynamic> j) => Entitlement(
        plan: (j['plan'] ?? 'free') as String,
        source: (j['source'] ?? 'none') as String,
        plusExpiresAt: j['plusExpiresAt'] is String
            ? DateTime.tryParse(j['plusExpiresAt'] as String)
            : null,
      );
}
