abstract class MellowtelException implements Exception {
  final Object message;

  MellowtelException(this.message);

  @override
  String toString() => 'Mellowtel Exception: $message';
}

class ScrapingException extends MellowtelException {
  ScrapingException(String message) : super(message);
}

class StorageException extends MellowtelException {
  StorageException(String message) : super(message);
}


class UserConsentDeniedError extends Error{}