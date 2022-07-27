import 'package:firebase_core/firebase_core.dart';

import '../constants/exceptions_messages.dart';

void checkIfFailedConnectionException(FirebaseException ex) {
  if (ex.message?.contains('Failed to connect') == true) {
    throw GENERIC_INTERNET_CONNECTION_ERROR_MSG;
  }
  throw GENERIC_ERROR_MSG;
}
