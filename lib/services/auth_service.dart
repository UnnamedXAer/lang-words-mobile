import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_words/models/app_user.dart';

import 'auth_exception.dart';
import 'exception.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AppUser? appUser;

  AuthService._internal() {
    addUserListener((user) {
      appUser = user;
    });
  }

  factory AuthService() => _instance;

  StreamSubscription<AppUser?> addUserListener(
      void Function(AppUser?) handler) {
    final StreamSubscription<AppUser?> subscription = _auth.userChanges().map(
      (User? user) {
        return (user != null ? AppUser.fromFirebaseUser(user) : null);
      },
    ).listen(handler);
    return subscription;
  }

  Future<String?> getIdToken() {
    if (_auth.currentUser == null) {
      return Future.value(null);
    }

    return _auth.currentUser!.getIdToken();
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
    }
  }

  void logout() async {
    try {
      await _auth.signOut();
    } catch (err) {
      log('logout: err: $err');
    }
  }

  Future<void> changePassword(String password, String newPassword) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw UnauthorizeException('currentUser is null');
    }
    if (user.email == null) {
      throw UnauthorizeException('currentUser.email is null');
    }

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      await _auth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (ex) {
      checkForReauthenticateExceptionCode(ex);
      checkForUpdatePasswordExceptionCode(ex);
      throw GenericException(ex);
    } on FirebaseException catch (ex) {
      checkForCommonFirebaseException(ex);
      throw GenericException(ex);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseException catch (ex) {
      checkForResetPasswordExceptionCode(ex);
      checkForCommonFirebaseException(ex);
      throw GenericException(ex);
    }
  }
}
