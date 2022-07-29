import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;

  AppUser({
    required this.uid,
    required this.email,
  });

  @override
  int get hashCode => Object.hash(uid.hashCode, email.hashCode);

  @override
  bool operator ==(other) {
    final equal = other is AppUser && other.uid == uid && other.email == email;
    return equal;
  }

  AppUser.fromFirebaseUser(User user)
      : uid = user.uid,
        email = user.email ?? "unknown";
}
