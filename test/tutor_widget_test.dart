import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/core/strings.dart';
import 'package:lurniq/models/models.dart';
import 'package:lurniq/screens/tutor/booking_detail_screen.dart';
import 'package:lurniq/screens/tutor/bookings_screen.dart';
import 'package:lurniq/screens/tutor/course_detail_screen.dart';
import 'package:lurniq/screens/tutor/quiz_runner.dart';
import 'package:lurniq/store/app_store.dart';
import 'package:provider/provider.dart';

/// Tutor-workstream widget tests, driven through the real UI on an
/// in-memory store ([AppStore.loadForTest] — no disk IO inside
/// testWidgets' FakeAsync zone).
Future<AppStore> signedInStore() async {
  final store = await AppStore.loadForTest();
  await store.signUp(
      displayName: 'Tutor Tester', username: 'tutor_tester');
  return store;
}

Widget withStore(AppStore store, Widget home) =>
    Provider<AppStore>.value(
      value: store,
      child: MaterialApp(home: home),
    );

void main() {
  testWidgets(
      'booking request shows as pending, then accepts to accepted',
      (tester) async {
    final store = await signedInStore();
    final booking = await store.requestBooking(
      tutorId: 'tutor-priya',
      tutorName: 'Priya Sharma',
      startsAtUtc:
          DateTime.now().toUtc().add(const Duration(hours: 2)),
      durationMin: 60,
      meetingLink: 'https://meet.example.com/x',
    );
    expect(booking.status, 'pending');

    await tester.pumpWidget(withStore(store, const BookingsScreen()));
    await tester.pumpAndSettle();

    // Pending tab lists the request.
    expect(find.text('Priya Sharma'), findsOneWidget);

    // Open the detail and use the demo tutor response row.
    await tester.tap(find.text('Priya Sharma'));
    await tester.pumpAndSettle();
    expect(find.text('Demo tutor response'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, S.accept));
    await tester.pumpAndSettle();

    expect(store.bookingById(booking.id)?.status, 'accepted');
    expect(find.text(S.bookingAccepted), findsOneWidget);
  });

  testWidgets('quiz runner: right answer scores, wrong one does not',
      (tester) async {
    final store = await signedInStore();
    final quiz = [
      QuizQuestion(
        id: 'q1',
        question: 'What is 2 + 2?',
        options: ['4', '5', '6'],
        correctIndex: 0,
        secondsPerQuestion: 3,
      ),
      QuizQuestion(
        id: 'q2',
        question: 'What is the capital of France?',
        options: ['London', 'Paris'],
        correctIndex: 1,
        secondsPerQuestion: 3,
      ),
    ];

    await tester.pumpWidget(
        withStore(store, QuizRunner(quiz: quiz, sessionId: 'test-quiz')));
    await tester.pumpAndSettle();

    // Q1: tap the correct option -> immediate Correct! feedback,
    // answer not revealed.
    await tester.tap(find.byKey(const Key('quiz-option-0')));
    await tester.pump();
    expect(find.text(S.correct), findsOneWidget);
    // Let the 3s timer expire (reveal) and the 2.5s reveal pause elapse.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    // Q2: tap the wrong option.
    expect(find.text('What is the capital of France?'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('quiz-option-0')));
    await tester.pump();
    expect(find.text(S.incorrect), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    // Score screen: 1/2, attempt submitted.
    expect(find.text(S.quizScore), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    final attempts = store.attemptsFor('test-quiz');
    expect(attempts.length, 1);
    expect(attempts.first.score, 1);
    expect(attempts.first.total, 2);
  });

  testWidgets(
      'course detail: enroll starts at 0%, marking a lesson done moves progress',
      (tester) async {
    final store = await signedInStore();
    // Seeded demo course with 4 lessons.
    expect(store.isEnrolled('course-bio-cells'), isFalse);

    await tester.pumpWidget(withStore(
        store, const CourseDetailScreen(courseId: 'course-bio-cells')));
    await tester.pumpAndSettle();

    await tester
        .tap(find.widgetWithText(FilledButton, S.enroll));
    await tester.pumpAndSettle();

    expect(store.isEnrolled('course-bio-cells'), isTrue);
    expect(store.courseProgress('course-bio-cells'), 0);
    expect(find.text('0%'), findsOneWidget);

    await tester.tap(
        find.widgetWithText(FilledButton.tonal, S.lessonDone).first);
    await tester.pumpAndSettle();

    expect(store.courseProgress('course-bio-cells'), 0.25);
    expect(find.text('25%'), findsOneWidget);
  });
}
