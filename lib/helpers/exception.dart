import 'package:lang_words/services/exception.dart';

class ValidationException extends AppException {
  ValidationException(String message, [Object? cause]) : super(message, cause);
}

class DuplicateException extends AppException {
  DuplicateException([String message = 'Item already exists', Object? cause])
      : super(message, cause);
}
