import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  AuthService._internal();

  factory AuthService() => _instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> authenticate(bool isLogin, String email, String password) async {
    final authFn = isLogin
        ? _auth.signInWithEmailAndPassword
        : _auth.createUserWithEmailAndPassword;

    try {
      final userCredential = await authFn(email: email, password: password);
      log('user: ${userCredential.user?.email}');
      log('user: ${userCredential.user?.uid}');
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
