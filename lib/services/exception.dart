import 'dart:developer';

import 'package:flutter/foundation.dart';

class NotFoundException implements Exception {
  final dynamic message;
  final dynamic cause;

  NotFoundException([this.message, this.cause]);

  @override
  String toString() {
    Object? message = this.message;
    if (message == null) return "Exception";
    return "Exception: $message";
  }
}

class GenericException implements Exception {
  @override
  String toString() {
    return "Exception: Something went wrong.";
  }
}

Future<void> tryCatch(Future<void> Function() fn, String errorLabel) async {
  try {
    await fn();
  } on Exception catch (ex) {
    rethrow;
  } catch (err) {
    log('$errorLabel, err: $err');
    if (kDebugMode) {
      rethrow;
    }
    throw GenericException();
  }
}
