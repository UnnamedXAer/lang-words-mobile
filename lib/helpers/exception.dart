class ValidationException implements Exception {
  final String _message;
  ValidationException(String message) : _message = message;

  String get message => _message;
}

class DuplicateException implements Exception {
  final String _message;
  DuplicateException([String message = 'Item already exists'])
      : _message = message;

  String get message => _message;
}
