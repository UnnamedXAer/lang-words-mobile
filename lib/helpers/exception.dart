class ValidationException implements Exception {
  final String _message;
  ValidationException(String message) : _message = message;

  String get message => _message;
}
