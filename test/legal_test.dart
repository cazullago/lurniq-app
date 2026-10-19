import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/core/utils.dart';
import 'package:lurniq/legal/legal_versions.dart';
import 'package:lurniq/models/models.dart';
import 'package:lurniq/store/app_store.dart';

/// Legal acceptance tests: sign-up requires ToS + Privacy Policy, and
/// listing a course/live session requires the Tutor Agreement.
void main() {
  Future<AppStore> freshStore() => AppStore.loadForTest();

  Future<AppStore> signedUpStore() async {
    final store = await freshStore();
    await store.signUp(
      displayName: 'Legal User',
      username: 'legaluser',
      tosAccepted: true,
      ppAccepted: true,
    );
    return store;
  }

  group('sign-up legal acceptance', () {
    test('sign-up without ToS acceptance throws', () async {
      final store = await freshStore();
      expect(
        () => store.signUp(
          displayName: 'A',
          username: 'nouser1',
          tosAccepted: false,
          ppAccepted: true,
        ),
        throwsA(isA<StoreException>()),
      );
      expect(store.currentUser, isNull);
    });

    test('sign-up without Privacy Policy acceptance throws', () async {
      final store = await freshStore();
      expect(
        () => store.signUp(
          displayName: 'B',
          username: 'nouser2',
          tosAccepted: true,
          ppAccepted: false,
        ),
        throwsA(isA<StoreException>()),
      );
      expect(store.currentUser, isNull);
    });

    test('accepted sign-up stamps version + timestamp', () async {
      final store = await signedUpStore();
      final u = store.currentUser!;
      expect(u.tosVersion, LegalVersions.tos);
      expect(u.ppVersion, LegalVersions.privacyPolicy);
      expect(u.tosAcceptedAt, isNotNull);
      expect(u.ppAcceptedAt, isNotNull);
    });

    test('acceptance survives a save/load round-trip', () async {
      final store = await signedUpStore();
      final json = store.currentUser!.toJson();
      final back = AppUser.fromJson(json);
      expect(back.tosVersion, LegalVersions.tos);
      expect(back.tosAcceptedAt, isNotNull);
    });
  });

  group('tutor agreement gate', () {
    test('createCourse without agreement throws', () async {
      final store = await signedUpStore();
      expect(store.tutorAgreementAccepted, isFalse);
      final before = store.courses.length;
      expect(
        () => store.createCourse(Course(
          id: 'c1',
          tutorId: store.currentUser!.id,
          title: 'X',
        )),
        throwsA(isA<StoreException>()),
      );
      expect(store.courses.length, before,
          reason: 'rejected listing must not be stored');
    });

    test('createLiveSession without agreement throws', () async {
      final store = await signedUpStore();
      final before = store.liveSessions.length;
      expect(
        () => store.createLiveSession(LiveSession(
          id: 'l1',
          tutorId: store.currentUser!.id,
          title: 'Live',
        )),
        throwsA(isA<StoreException>()),
      );
      expect(store.liveSessions.length, before,
          reason: 'rejected listing must not be stored');
    });

    test('accepting the agreement unlocks listing', () async {
      final store = await signedUpStore();
      await store.acceptTutorAgreement();
      expect(store.tutorAgreementAccepted, isTrue);
      final u = store.currentUser!;
      expect(u.tutorAgreementVersion, LegalVersions.tutorAgreement);
      expect(u.tutorAgreementAt, isNotNull);

      final coursesBefore = store.courses.length;
      await store.createCourse(Course(
        id: 'c1',
        tutorId: u.id,
        title: 'My course',
      ));
      expect(store.courses.length, coursesBefore + 1);

      final liveBefore = store.liveSessions.length;
      await store.createLiveSession(LiveSession(
        id: 'l1',
        tutorId: u.id,
        title: 'My live',
      ));
      expect(store.liveSessions.length, liveBefore + 1);
    });

    test('updateCourse (edit) does not require re-acceptance', () async {
      final store = await signedUpStore();
      await store.acceptTutorAgreement();
      final course = Course(
        id: 'c1',
        tutorId: store.currentUser!.id,
        title: 'Draft',
      );
      await store.createCourse(course);
      course.title = 'Renamed';
      await store.updateCourse(course);
      expect(store.courseById('c1')!.title, 'Renamed');
    });
  });
}
