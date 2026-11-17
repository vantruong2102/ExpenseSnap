import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/app_user.dart';
import 'package:frontend/services/auth_service.dart';

class _FakeFirebaseAuth implements FirebaseAuth {
  _FakeFirebaseAuth({this.currentUser});

  @override
  final User? currentUser;

  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthSession', () {
    final session = AuthSession.instance;

    tearDown(() => session.clear());

    test('isSignedIn reflects whether an access token exists', () {
      session.clear();
      expect(session.isSignedIn, isFalse);

      session.accessToken = 'access-token';
      expect(session.isSignedIn, isTrue);
    });

    test('clear removes user and both tokens on logout', () {
      session
        ..user = const AppUser(id: 7, email: 'tri@example.com', fullName: 'Tri')
        ..accessToken = 'access-token'
        ..refreshToken = 'refresh-token';

      session.clear();

      expect(session.user, isNull);
      expect(session.accessToken, isNull);
      expect(session.refreshToken, isNull);
      expect(session.isSignedIn, isFalse);
    });
    test('AuthService.signOut clears session and signs out Firebase', () async {
      final firebaseAuth = _FakeFirebaseAuth();
      session
        ..user = const AppUser(id: 7, email: 'tri@example.com', fullName: 'Tri')
        ..accessToken = 'access-token'
        ..refreshToken = 'refresh-token';

      await AuthService(firebaseAuth: firebaseAuth, session: session).signOut();

      expect(firebaseAuth.signOutCalls, 1);
      expect(session.isSignedIn, isFalse);
      expect(session.user, isNull);
      expect(session.refreshToken, isNull);
    });

    test('restoreSession clears stale backend session when Firebase user is absent', () async {
      final firebaseAuth = _FakeFirebaseAuth();
      session
        ..user = const AppUser(id: 7, email: 'tri@example.com', fullName: 'Tri')
        ..accessToken = 'stale-access-token'
        ..refreshToken = 'stale-refresh-token';

      final restored = await AuthService(firebaseAuth: firebaseAuth, session: session).restoreSession();

      expect(restored, isFalse);
      expect(session.isSignedIn, isFalse);
      expect(session.user, isNull);
      expect(session.refreshToken, isNull);
    });
  });
}
