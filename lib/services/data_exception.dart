import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../constants/exceptions_messages.dart';
import 'exception.dart';

class NotFoundException extends AppException {
  NotFoundException([
    String? message,
    Object? cause,
  ]) : super(message ?? GENERIC_ERROR_MSG, cause);
}

Future<T> tryCatch<T>(
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

    log('$errorLabel: ex: $appException');

    throw appException;
  }
}
