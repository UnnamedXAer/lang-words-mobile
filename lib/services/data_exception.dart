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

Future<T> tryCatch<T>(Future<T> Function() fn, String errorLabel) async {
  try {
    return await fn();
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
