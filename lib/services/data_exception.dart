import 'dart:developer';

import 'package:flutter/foundation.dart';

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
    log('$errorLabel, err: $ex');
    rethrow;
  } catch (err) {
    log('$errorLabel, err: $err');
    if (kDebugMode) {
      rethrow;
    }
    throw GenericException();
  }
}
