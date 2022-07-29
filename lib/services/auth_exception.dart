import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_words/services/exception.dart';

import '../constants/exceptions_messages.dart';

void checkForAuthExceptionCode(FirebaseException ex) {
  switch (ex.code) {
    case 'network-request-failed':
      throw AppException(GENERIC_SERVER_UNREACHABLE_ERROR_MSG, ex);
    case 'invalid-email':
      throw AppException('Incorrect Email Address.', ex);
    case 'user-not-found':
      throw AppException('Incorrect credentials.', ex);
    case 'wrong-password':
      throw AppException('Incorrect credentials.', ex);
    case 'weak-password':
      throw AppException('Password should be at least 6 characters.', ex);
    case 'unknown':
      throw AppException(
          'Sorry, bizarro error occurred on the server side, please try again later.',
          ex);
  }
}
