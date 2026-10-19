import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/core/constants.dart';
import 'package:lurniq/core/utils.dart';
import 'package:lurniq/models/models.dart';
import 'package:lurniq/store/app_store.dart';

/// Store-level tests for the critical Phase 1 flows. The store is the single
/// source of truth; widget tests (widget_test.dart) drive the same flows
/// through the UI.
Future<AppStore> freshStore() async {
  final dir =
      await Directory.systemTemp.createTemp('lurniq_store_test');
  return AppStore.load(dir);
}

Future<AppStore> signedInStore() async {
  final store = await freshStore();
  await store.signUp(
      displayName: 'Test User', username: 'testuser', tosAccepted: true, ppAccepted: true);
  return store;
}

void main() {
  group('Auth session persistence', () {
    test('sign up creates a session that survives a restart',
        () async {
      final store = await freshStore();
      await store.signUp(
          displayName: 'Test User', username: 'testuser', tosAccepted: true, ppAccepted: true);
      expect(store.currentUser?.username, 'testuser');
      expect(store.myFolders.length, 6,
          reason: 'default subject folders are seeded');

      await store.flush();
      final reloaded = await AppStore.load(store.appDir);
      expect(reloaded.currentUser?.username, 'testuser',
          reason: 'session restored from disk');
      expect(reloaded.myFolders.length, 6);
    });

    test('duplicate usernames are rejected', () async {
      final store = await freshStore();
      await store.signUp(
          displayName: 'A', username: 'someone', tosAccepted: true, ppAccepted: true);
      expect(
        () => store.signUp(
            displayName: 'B', username: 'Someone', tosAccepted: true, ppAccepted: true),
        throwsA(isA<StoreException>()),
      );
    });

    test('sign out clears the session', () async {
      final store = await signedInStore();
      await store.signOut();
      expect(store.currentUser, isNull);
      await store.flush();
      final reloaded = await AppStore.load(store.appDir);
      expect(reloaded.currentUser, isNull);
    });

    test('delete account wipes the user and their data',
        () async {
      final store = await signedInStore();
      final folder = store.myFolders.first;
      await store.addTask(
          title: 'Homework', folderId: folder.id);
      await store.addLesson(
        folderId: folder.id,
        title: 'Lesson 1',
        photoPath: '/tmp/fake.jpg',
      );
      await store.createPost(Post(
        id: newId(),
        authorId: '',
        authorName: '',
        type: 'discussion',
        body: 'hello',
      ));
      await store.deleteAccount();
      expect(store.currentUser, isNull);
      expect(store.users.any((u) => u.username == 'testuser'),
          isFalse);
      expect(store.myTasks, isEmpty);
      expect(store.posts.any((p) => p.body == 'hello'),
          isFalse);
    });
  });

  group('Newsfeed', () {
    test('create post -> like -> bookmark -> comment -> reply',
        () async {
      final store = await signedInStore();
      final post = await store.createPost(Post(
        id: newId(),
        authorId: '',
        authorName: '',
        type: 'question',
        title: 'Why is the sky blue?',
        body: 'Looking for an explanation.',
        subject: 'Science',
        level: 'Middle School',
        tags: ['physics'],
      ));
      expect(
          store.feedPosts().any((p) => p.id == post.id),
          isTrue);
      expect(
          store
              .feedPosts(query: 'sky blue')
              .any((p) => p.id == post.id),
          isTrue);

      store.toggleLike(post.id);
      expect(post.likes.length, 1);
      store.toggleBookmark(post.id);
      expect(
          store
              .feedPosts(savedOnly: true)
              .any((p) => p.id == post.id),
          isTrue);

      final comment = await store.addComment(
          postId: post.id, body: 'Rayleigh scattering!');
      final reply = await store.addComment(
          postId: post.id,
          body: 'Thanks!',
          parentId: comment.id);
      expect(store.commentsFor(post.id).length, 2);
      expect(
          store.repliesFor(comment.id).single.id, reply.id);

      store.markHelpful(post.id, comment.id);
      expect(comment.isHelpful, isTrue);
      store.setResolved(post.id, true);
      expect(post.resolved, isTrue);
    });

    test('non-authors cannot mark helpful or resolve', () async {
      final store = await signedInStore();
      final post = await store.createPost(Post(
        id: newId(),
        authorId: '',
        authorName: '',
        body: 'q',
      ));
      await store.signOut();
      await store.signUp(
          displayName: 'Other', username: 'other1', tosAccepted: true, ppAccepted: true);
      final comment = await store.addComment(
          postId: post.id, body: 'answer');
      store.markHelpful(post.id, comment.id);
      expect(comment.isHelpful, isFalse);
      store.setResolved(post.id, true);
      expect(post.resolved, isFalse);
    });

    test('reports create open reports for moderators',
        () async {
      final store = await signedInStore();
      store.addReport(
        targetType: 'post',
        targetId: 'x',
        targetSummary: 'spam post',
        reason: 'Spam or misleading',
      );
      expect(store.openReports.length, 1);
      store.resolveReport(
          store.openReports.first.id, 'dismissed');
      expect(store.openReports, isEmpty);
      expect(
          store.adminLog
              .any((e) => e.action == 'report_dismissed'),
          isTrue);
    });
  });

  group('Study groups', () {
    test('join -> approve -> leave -> cancel', () async {
      final store = await signedInStore();
      final post = await store.createPost(Post(
        id: newId(),
        authorId: '',
        authorName: '',
        type: 'studyGroup',
        title: 'Algebra jam',
        groupStartsAtUtc:
            DateTime.now().toUtc().add(const Duration(days: 1)),
        groupMaxParticipants: 2,
        groupFormat: 'online',
      ));
      // Organizer auto-joins.
      expect(post.participantIds.length, 1);

      await store.signOut();
      await store.signUp(
          displayName: 'Joiner', username: 'joiner1', tosAccepted: true, ppAccepted: true);
      store.requestJoinGroup(post.id);
      expect(post.participantIds.length, 2);

      await store.signOut();
      await store.signUp(
          displayName: 'Waitlister', username: 'waiter1', tosAccepted: true, ppAccepted: true);
      store.requestJoinGroup(post.id);
      expect(post.pendingIds.length, 1,
          reason: 'group is full -> waitlist');

      // Organizer approves once a spot frees up.
      await store.signIn('testuser');
      store.leaveGroup(post.id); // organizer leaves (edge case)
      store.approveParticipant(post.id, post.pendingIds.first);
      expect(post.participantIds.length, 2);

      store.cancelGroup(post.id);
      expect(post.groupCancelled, isTrue);
    });
  });

  group('Planner folders', () {
    test('folder CRUD + reorder', () async {
      final store = await signedInStore();
      final initial = store.myFolders.length;

      final folder = await store.addFolder(
        name: 'Art',
        colorValue: 0xFFDB2777,
        icon: 'palette',
      );
      expect(store.myFolders.length, initial + 1);

      await store.renameFolder(folder.id,
          name: 'Fine Arts',
          colorValue: 0xFFDB2777,
          icon: 'palette');
      expect(
          store.folderById(folder.id)?.name, 'Fine Arts');

      // Move it to the front.
      await store.moveFolder(
          store.myFolders.length - 1, 0);
      expect(store.myFolders.first.id, folder.id);

      await store.deleteFolder(folder.id);
      expect(store.folderById(folder.id), isNull);
      expect(store.myFolders.length, initial);
    });

    test('lessons are saved and searchable', () async {
      final store = await signedInStore();
      final folder = store.myFolders.first;
      await store.addLesson(
        folderId: folder.id,
        title: 'Fractions intro',
        photoPath: '/tmp/fractions.jpg',
        notes: 'Numerator over denominator',
        tags: ['fractions', 'math'],
      );
      expect(store.lessonsIn(folder.id).length, 1);
      expect(
          store.searchLessons('FRACTIONS').length, 1);
      expect(store.searchLessons('numerator').length, 1);
      expect(store.searchLessons('zzz-no-match'), isEmpty);
    });
  });

  group('Planner tasks', () {
    test('task CRUD, status, overdue detection', () async {
      final store = await signedInStore();
      final folder = store.myFolders.first;

      final overdue = await store.addTask(
        title: 'Overdue homework',
        folderId: folder.id,
        dueAtLocal: DateTime.now()
            .subtract(const Duration(days: 1)),
        priority: 'high',
      );
      expect(overdue.isOverdue, isTrue);
      expect(store.overdueTasks.length, 1);

      final future = await store.addTask(
        title: 'Future quiz',
        dueAtLocal:
            DateTime.now().add(const Duration(days: 3)),
      );
      expect(store.upcomingTasks().length, 1);

      store.setTaskStatus(overdue.id, 'done');
      expect(overdue.isDone, isTrue);
      expect(overdue.isOverdue, isFalse);
      expect(store.overdueTasks, isEmpty);

      final todayTask = await store.addTask(
        title: 'Due today',
        dueAtLocal: DateTime.now().add(
            const Duration(hours: 2)),
      );
      final today = DateTime.now();
      expect(store.tasksForDay(today).length, 1);

      future.title = 'Renamed quiz';
      await store.updateTask(future);
      expect(
          store.myTasks
              .firstWhere((t) => t.id == future.id)
              .title,
          'Renamed quiz');

      await store.deleteTask(future.id);
      await store.deleteTask(todayTask.id);
      expect(
          store.myTasks.any((t) => t.id == future.id),
          isFalse);
    });
  });

  group('Tutors', () {
    test('seeded directory filters and sorts', () async {
      final store = await freshStore();
      expect(store.tutors.length, 8);
      expect(store.tutors.every((t) => t.isDemo), isTrue);

      final free =
          store.findTutors(freeOnly: true);
      expect(free.length, 1);
      expect(free.first.priceUsd, 0);

      final math = store.findTutors(
          subject: 'Mathematics', minRating: 4.8);
      expect(math.length, 2);

      final sorted =
          store.findTutors(sort: 'priceLow');
      for (var i = 1; i < sorted.length; i++) {
        expect(
            sorted[i].priceUsd >=
                sorted[i - 1].priceUsd,
            isTrue);
      }

      final queried =
          store.findTutors(query: 'guitar');
      expect(queried.length, 1);
    });

    test('reviews update the tutor aggregate', () async {
      final store = await signedInStore();
      final tutor = store.tutors.first;
      final before = tutor.reviewCount;
      await store.addTutorReview(
          tutorId: tutor.id,
          rating: 5,
          text: 'Great tutor!');
      expect(tutor.reviewCount, before + 1);
      expect(
          store.reviewsFor(tutor.id).length, 1);
    });

    test('tutor interest is recorded', () async {
      final store = await freshStore();
      await store.addTutorInterest(
          name: 'Sam',
          contact: 'sam@example.com',
          subjects: 'Physics');
      expect(store.tutorInterests.length, 1);
    });
  });

  group('Admin', () {
    test('passcode gate, audit log, commission', () async {
      final store = await freshStore();
      expect(store.verifyAdmin('wrong'), isFalse);
      expect(store.verifyAdmin(C.adminPasscode), isTrue);
      expect(
          store.adminLog
              .any((e) => e.action == 'admin_login'),
          isTrue);

      store.setCommissionRate(0.2);
      expect(store.commissionRate, 0.2);
      expect(
          store.adminLog.any(
              (e) => e.action == 'commission_changed'),
          isTrue);

      store.addAnnouncement('Hi', 'Welcome!');
      expect(store.activeAnnouncements.length, 1);

      await store.flush();
      final reloaded = await AppStore.load(store.appDir);
      expect(reloaded.commissionRate, 0.2);
      expect(reloaded.activeAnnouncements.length, 1);
    });
  });

  group('Seed content', () {
    test('demo posts and folders are labeled', () async {
      final store = await freshStore();
      expect(store.posts.isNotEmpty, isTrue);
      expect(store.posts.every((p) => p.isDemo), isTrue);
      expect(store.comments.every((c) => c.isDemo), isTrue);
      await store.signUp(
          displayName: 'U', username: 'u123', tosAccepted: true, ppAccepted: true);
      await store.clearDemoContent();
      expect(store.posts, isEmpty);
      expect(store.comments, isEmpty);
      expect(store.tutors, isNotEmpty,
          reason: 'tutors stay until Phase 3');
    });
  });
}
