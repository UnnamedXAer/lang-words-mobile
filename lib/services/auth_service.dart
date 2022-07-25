import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_words/models/app_user.dart';

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
    } on FirebaseAuthException catch (ex) {
      log('authenticate: auth ex: $ex');
      rethrow;
    } on Exception catch (ex) {
      log('authenticate: ex: $ex');
      rethrow;
    } catch (err) {
      log('authenticate: err: $err');
      rethrow;
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
