import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/core/ai_service.dart';
import 'package:lurniq/screens/planner/task_form_screen.dart';
import 'package:lurniq/store/app_store.dart';
import 'package:provider/provider.dart';

/// v2 planner tests for this workstream.
///
/// Widget tests use [AppStore.loadForTest] (MemoryJsonBox): real async file
/// IO deadlocks inside testWidgets' FakeAsync zone, so the disk is never
/// touched there. Pure `test()` suites use [AppStore.load] with temp dirs,
/// like store_test.dart.
Future<AppStore> signedInStore() async {
  final store = await AppStore.loadForTest();
  await store.signUp(
      displayName: 'Planner Tester', username: 'planner_tester');
  return store;
}

Widget _formHarness(AppStore store, {String? taskId}) {
  return ChangeNotifierProvider<AppStore>.value(
    value: store,
    child: MaterialApp(
      home: TaskFormScreen(taskId: taskId),
    ),
  );
}

void main() {
  group('AiService', () {
    test('ask without key returns non-empty demo guidance', () async {
      final store = await AppStore.loadForTest();
      expect(store.aiApiKey, isNull);
      final answer =
          await AiService.ask(store, 'How do I study fractions?');
      expect(answer.isNotEmpty, isTrue);
      expect(answer.toLowerCase(), contains('demo'),
          reason: 'demo output must be labeled as demo');
    });

    test('ask with context explains the concept', () async {
      final store = await AppStore.loadForTest();
      final answer = await AiService.ask(
        store,
        'Explain this to me',
        context: 'Lesson: Photosynthesis. Notes: leaves use sunlight.',
      );
      expect(answer.isNotEmpty, isTrue);
      expect(answer, contains('Photosynthesis'));
    });

    test('empty prompt returns guidance, not an error', () async {
      final store = await AppStore.loadForTest();
      final answer = await AiService.ask(store, '   ');
      expect(answer.isNotEmpty, isTrue);
    });
  });

  group('completeTask / reopenTask / saveGrade', () {
    test('complete moves a task from openTasks to doneTasks', () async {
      final store = await signedInStore();
      final task = await store.addTask(title: 'Algebra homework');

      expect(
          store.openTasks().any((t) => t.id == task.id), isTrue);
      expect(
          store.doneTasks().any((t) => t.id == task.id), isFalse);

      await store.completeTask(task.id);

      expect(task.isDone, isTrue);
      expect(task.completedAt, isNotNull);
      expect(
          store.openTasks().any((t) => t.id == task.id), isFalse);
      expect(
          store.doneTasks().any((t) => t.id == task.id), isTrue);

      await store.reopenTask(task.id);
      expect(task.isDone, isFalse);
      expect(
          store.openTasks().any((t) => t.id == task.id), isTrue);
      expect(
          store.doneTasks().any((t) => t.id == task.id), isFalse);
    });

    test('saveGrade round-trips score, note, and photo path',
        () async {
      final store = await signedInStore();
      final task = await store.addTask(title: 'History essay');
      await store.completeTask(task.id);

      await store.saveGrade(
        task.id,
        score: '95/100',
        note: 'Excellent thesis',
        photoPath: '/tmp/grade.jpg',
      );

      final reloaded = store.taskById(task.id)!;
      expect(reloaded.gradeScore, '95/100');
      expect(reloaded.gradeNote, 'Excellent thesis');
      expect(reloaded.gradePhotoPath, '/tmp/grade.jpg');

      // Updating the grade replaces the old one.
      await store.saveGrade(task.id, score: 'A');
      final again = store.taskById(task.id)!;
      expect(again.gradeScore, 'A');
      expect(again.gradePhotoPath, '/tmp/grade.jpg',
          reason: 'photo persists when no new photo is given');
    });

    test('doneTasks are the performance record, newest first',
        () async {
      final store = await signedInStore();
      final first = await store.addTask(title: 'Task one');
      final second = await store.addTask(title: 'Task two');
      await store.completeTask(first.id);
      await store.completeTask(second.id);

      final done = store.doneTasks();
      expect(done.length, 2);
      expect(done.first.id, second.id,
          reason: 'most recently completed task first');
    });
  });

  group('task form layout regression', () {
    testWidgets('create form renders at 360x640 without overflow',
        (tester) async {
      // Narrow phone viewport (the v1 "New task" screen overflowed by
      // ~50px on real devices).
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final store = await signedInStore();
      await tester.pumpWidget(_formHarness(store));
      await tester.pumpAndSettle();

      expect(find.text('Task title'), findsOneWidget);
      expect(find.text('Save task'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'no layout overflow on a 360-wide viewport');
    });

    testWidgets('edit form renders at 360x640 without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final store = await signedInStore();
      final task = await store.addTask(
        title: 'Existing task with a long title',
        instructions: 'Do the thing',
        notes: 'Some notes',
        priority: 'high',
        reminder: true,
      );
      task.taskType = 'other';
      task.taskTypeCustom = 'Lab report';
      await store.updateTask(task);

      await tester.pumpWidget(
          _formHarness(store, taskId: task.id));
      await tester.pumpAndSettle();

      expect(find.text('Existing task with a long title'),
          findsOneWidget);
      expect(find.text('Lab report'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'no layout overflow on a 360-wide viewport');
    });
  });
}
