import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_words/models/app_user.dart';

import 'auth_exception.dart';
import 'exception.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService._internal();

  factory AuthService() => _instance;

  StreamSubscription<AppUser?> addUserListener(
      void Function(AppUser?) handler) {
    final StreamSubscription<AppUser?> subscription = _auth
        .userChanges()
        .map(
          (User? user) =>
              (user != null ? AppUser.fromFirebaseUser(user) : null),
        )
        .listen(handler);
    return subscription;
  }

  Future<void> authenticate(bool isLogin, String email, String password) async {
    final authFn = isLogin
        ? _auth.signInWithEmailAndPassword
        : _auth.createUserWithEmailAndPassword;

    try {
      final userCredential = await authFn(email: email, password: password);
      log('user: ${userCredential.user?.email}, user: ${userCredential.user?.uid}');
    } on FirebaseAuthException catch (authEx) {
      log('authenticate: FirebaseAuthException ex: $authEx');

      checkForAuthExceptionCode(authEx);
      checkForCommonFirebaseException(authEx);
      throw GenericException(authEx);
    } on Exception catch (ex) {
      log('authenticate: ex: $ex');
      throw GenericException(ex);
    } catch (err) {
      log('authenticate: err: $err');
      throw GenericException(err);
    }
  }

  void logout() async {
    try {
      await _auth.signOut();
    } catch (err) {
      log('logout: err: $err');
    }
  }
}