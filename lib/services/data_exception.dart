import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../constants/exceptions_messages.dart';
import 'exception.dart';
import 'words_service.dart';

class NotFoundException extends AppException {
  NotFoundException([
    String? message,
    Object? cause,
  ]) : super(message ?? GENERIC_ERROR_MSG, cause);
}

Future<T> firebaseTryCatch<T>(
    String? uid, Future<T> Function(String uid) fn, String errorLabel) async {
  if (uid == null) {
    throw UnauthorizeException('$errorLabel: uid is null');
  }
  try {
    return await fn(uid);
  } on Exception catch (ex) {
    AppException appException;

    switch (ex.runtimeType) {
      case FirebaseException:
        try {
          checkIfFailedConnectionException(ex as FirebaseException);
          checkForCommonFirebaseException(ex);
          appException = GenericException(ex);
        } on AppException catch (ex) {
          appException = ex;
        }
        break;
      case TimeoutException:
      case SocketException:
        appException = AppException(
          GENERIC_INTERNET_CONNECTION_ERROR_MSG,
          ex,
        );
        break;
      default:
        appException = GenericException(ex);
    }

    // TODO: find a way to disable caching for firebase realtime database globally
    final ws = WordsService();
    await ws.purgeOutstandingFirebaseWrites();

    log('⚠️ $errorLabel: ex: $appException');

    throw appException;
  }
}
