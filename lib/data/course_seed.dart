import '../models/models.dart';

/// Demo courses + live sessions shown in the Tutor tab. Everything here is
/// labeled "DEMO" in the UI and removable via Settings → Clear demo content.
/// The tutor-tab owner may extend these lists; the store wires them in.
class CourseSeed {
  static List<Course> demoCourses() => [
        Course(
          id: 'course-bio-cells',
          tutorId: 'tutor-priya',
          tutorName: 'Priya Sharma',
          title: 'Biology: How Cells Work',
          description:
              'A friendly tour of the cell — membranes, organelles, and what each part actually does. Perfect before your first biology exam.',
          subject: 'Biology',
          level: 'High School',
          priceUsd: 0,
          published: true,
          rating: 4.8,
          reviewCount: 96,
          enrollmentCount: 1240,
          isDemo: true,
        ),
        Course(
          id: 'course-python-basics',
          tutorId: 'tutor-james',
          tutorName: 'James Okafor',
          title: 'Python Basics for Beginners',
          description:
              'Write your first real programs: variables, loops, and functions, with tiny exercises after every lesson.',
          subject: 'Computer Science',
          level: 'College',
          priceUsd: 15,
          published: true,
          rating: 4.9,
          reviewCount: 187,
          enrollmentCount: 2315,
          isDemo: true,
        ),
        Course(
          id: 'course-algebra',
          tutorId: 'tutor-maria',
          tutorName: 'Maria Santos',
          title: 'Algebra Foundations',
          description:
              'From solving x to factoring quadratics — short lessons that build on each other, with practice in every step.',
          subject: 'Mathematics',
          level: 'High School',
          priceUsd: 9,
          published: true,
          rating: 4.7,
          reviewCount: 142,
          enrollmentCount: 1876,
          isDemo: true,
        ),
      ];

  static List<CourseLesson> demoLessons() => [
        // Biology: How Cells Work
        CourseLesson(
          id: 'cl-bio-1',
          courseId: 'course-bio-cells',
          title: 'Meet the cell',
          kind: 'slides',
          body:
              'Every living thing is built from cells. Think of a cell as a tiny factory: it takes in raw materials, builds what the body needs, and ships out waste.\n\nKey idea: structure matches function. A part\'s shape tells you its job.',
          durationMin: 8,
          order: 0,
        ),
        CourseLesson(
          id: 'cl-bio-2',
          courseId: 'course-bio-cells',
          title: 'The membrane: the bouncer',
          kind: 'slides',
          body:
              'The cell membrane controls what enters and leaves. It is picky on purpose — nutrients in, toxins out.\n\nRemember: "selectively permeable" = chooses what passes.',
          durationMin: 10,
          order: 1,
        ),
        CourseLesson(
          id: 'cl-bio-3',
          courseId: 'course-bio-cells',
          title: 'Mitochondria make energy',
          kind: 'slides',
          body:
              'Mitochondria turn food into ATP — the energy currency every cell spends. Muscle cells have thousands; that\'s why exercise builds more of them.\n\nMnemonic: "mighty mitochondria make money (ATP)".',
          durationMin: 9,
          order: 2,
        ),
        CourseLesson(
          id: 'cl-bio-4',
          courseId: 'course-bio-cells',
          title: 'Nucleus: the control room',
          kind: 'slides',
          body:
              'The nucleus stores DNA — the instruction manual for building proteins. Everything the cell does starts as a message copied from here.\n\nQuick check: which organelle would a skin cell use most? (Hint: protection and repair need lots of protein.)',
          durationMin: 7,
          order: 3,
        ),
        // Python Basics
        CourseLesson(
          id: 'cl-py-1',
          courseId: 'course-python-basics',
          title: 'Your first program',
          kind: 'slides',
          body:
              'print("Hello, world!")\n\nThat one line tells the computer to display text. Every program is just instructions written plainly enough for a very literal machine.',
          durationMin: 6,
          order: 0,
        ),
        CourseLesson(
          id: 'cl-py-2',
          courseId: 'course-python-basics',
          title: 'Variables are labeled boxes',
          kind: 'slides',
          body:
              'name = "Ada"\nage = 16\n\nA variable stores a value under a name. Change the value any time: age = 17. The computer remembers the latest one.',
          durationMin: 10,
          order: 1,
        ),
        CourseLesson(
          id: 'cl-py-3',
          courseId: 'course-python-basics',
          title: 'Loops do the boring work',
          kind: 'slides',
          body:
              'for i in range(5):\n    print(i)\n\nA loop repeats instructions. range(5) counts 0–4. Whenever you catch yourself copying lines, you probably want a loop.',
          durationMin: 12,
          order: 2,
        ),
        // Algebra Foundations
        CourseLesson(
          id: 'cl-alg-1',
          courseId: 'course-algebra',
          title: 'Solving for x',
          kind: 'slides',
          body:
              'x + 7 = 15. Undo the +7 by subtracting 7 from BOTH sides: x = 8.\n\nGolden rule: whatever you do to one side, do to the other. The equals sign is a balance scale.',
          durationMin: 8,
          order: 0,
        ),
        CourseLesson(
          id: 'cl-alg-2',
          courseId: 'course-algebra',
          title: 'Two-step equations',
          kind: 'slides',
          body:
              '3x + 4 = 19. Step 1: subtract 4 → 3x = 15. Step 2: divide by 3 → x = 5.\n\nUndo in reverse order: addition/subtraction first, then multiplication/division.',
          durationMin: 10,
          order: 1,
        ),
        CourseLesson(
          id: 'cl-alg-3',
          courseId: 'course-algebra',
          title: 'Factoring quadratics',
          kind: 'slides',
          body:
              'x² + 5x + 6 = (x + 2)(x + 3). Find two numbers that multiply to 6 and add to 5: 2 and 3.\n\nCheck by expanding: (x+2)(x+3) = x² + 3x + 2x + 6. ✓',
          durationMin: 14,
          order: 2,
        ),
      ];

  static List<LiveSession> demoLiveSessions() => [
        LiveSession(
          id: 'live-sci-qa',
          tutorId: 'tutor-priya',
          tutorName: 'Priya Sharma',
          title: 'Live: Science Q&A — Ask Me Anything',
          subject: 'Science',
          description:
              'Bring your hardest science questions. We\'ll finish with a quick-fire quiz — answers revealed live!',
          startsAtUtc:
              DateTime.now().toUtc().add(const Duration(hours: 3)),
          durationMin: 45,
          meetingLink: 'https://meet.google.com/demo-lurniq-science',
          status: 'scheduled',
          quiz: [
            QuizQuestion(
              id: 'q1',
              question: 'Which organelle produces most of the cell\'s ATP?',
              options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Cell wall'],
              correctIndex: 1,
              secondsPerQuestion: 20,
            ),
            QuizQuestion(
              id: 'q2',
              question: 'What does "selectively permeable" mean?',
              options: [
                'Nothing can pass',
                'Everything passes freely',
                'Only some substances pass',
                'Only water passes'
              ],
              correctIndex: 2,
              secondsPerQuestion: 20,
            ),
            QuizQuestion(
              id: 'q3',
              question: 'Where is DNA stored in the cell?',
              options: [
                'Mitochondria',
                'Cytoplasm',
                'Nucleus',
                'Cell membrane'
              ],
              correctIndex: 2,
              secondsPerQuestion: 15,
            ),
          ],
          isDemo: true,
        ),
      ];
}
