/// An error thrown when an error is encountered when accessing the API.
class LibreTranslateException implements Exception {
  /// The message for this exception.
  final String message;

  /// Create a new [LibreTranslateException].
  LibreTranslateException(this.message);

  @override
  String toString() => 'LibreTranslateException: $message';
}
