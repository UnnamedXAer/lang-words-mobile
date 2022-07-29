import 'package:firebase_auth/firebase_auth.dart';

import '../constants/exceptions_messages.dart';

class AppException implements Exception {
  final String _message;
  final Object? _cause;
  AppException([this._message = GENERIC_ERROR_MSG, this._cause]);

  @override
  String toString() {
    return "Exception: $_message, cause: $_cause";
  }

  String get message => _message;
}

class GenericException extends AppException {
  GenericException([Object? cause]) : super(GENERIC_ERROR_MSG, cause);
}

void checkForCommonFirebaseException(FirebaseException ex) {
  switch (ex.code) {
    case 'operation-not-allowed':
      throw AppException('This operation is not allowed.', ex.message);
    case 'too-many-requests':
      throw AppException(
        'We received too many requests, you will need to wait a while to continue.',
        ex.message,
      );
  }

  checkIfFailedConnectionException(ex);
}

void checkIfFailedConnectionException(FirebaseException ex) {
  if (ex.message?.contains('Failed to connect') == true) {
    throw AppException(GENERIC_INTERNET_CONNECTION_ERROR_MSG, ex.message);
  }
}
