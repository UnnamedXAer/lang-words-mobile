import 'package:firebase_auth/firebase_auth.dart';

import '../constants/exceptions_messages.dart';
import 'exception.dart';

void checkForAuthExceptionCode(FirebaseException ex) {
  switch (ex.code) {
    case 'network-request-failed':
      throw AppException(GENERIC_SERVER_UNREACHABLE_ERROR_MSG, ex);
    case 'invalid-email':
      throw AppException('Incorrect Email Address.', ex);
    case 'email-already-in-use':
      throw AppException(
          'The email address is already in use by another account.', ex);
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

void checkForReauthenticateExceptionCode(FirebaseException ex) {
  const codeResponses = <String, String>{
    "user-mismatch": 'Re-login required.',
    "user-not-found": 'Wrong password.',
    "invalid-credential": 'Wrong password.',
    "invalid-email": 'Re-login required.',
    "wrong-password": 'Wrong password.',
    "invalid-verification-code": 'Re-login required.',
    "invalid-verification-id": 'Re-login required.',
  };

  if (codeResponses.containsKey(ex.code)) {
    throw AppException(codeResponses[ex.code]!, ex);
  }
}

void checkForUpdatePasswordExceptionCode(FirebaseException ex) {
  const codeResponses = <String, String>{
    "weak-password": 'Password should be at least 6 characters.',
    "requires-recent-login": 'Re-login required.',
  };

  if (codeResponses.containsKey(ex.code)) {
    throw AppException(codeResponses[ex.code]!, ex);
  }
}

void checkForResetPasswordExceptionCode(FirebaseException ex) {
  const codeResponses = <String, String>{
    'invalid-email': 'Incorrect Email Address.',
    'missing-android-pkg-name': GENERIC_ERROR_MSG,
    'missing-continue-uri': GENERIC_ERROR_MSG,
    'missing-ios-bundle-id': GENERIC_ERROR_MSG,
    'invalid-continue-uri': GENERIC_ERROR_MSG,
    'unauthorized-continue-uri': GENERIC_ERROR_MSG,
    'user-not-found': 'There is no user with corresponding email address.',
  };

  if (codeResponses.containsKey(ex.code)) {
    throw AppException(codeResponses[ex.code]!, ex);
  }
}
