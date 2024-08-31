abstract class MellowtelException implements Exception {
  final Object message;

  MellowtelException(this.message);

  @override
  String toString() => 'Mellowtel Exception: $message';
}

class ScrapingException extends MellowtelException {
  ScrapingException(super.message);
}

class StorageException extends MellowtelException {
  StorageException(super.message);
}


class UserConsentDeniedError extends Error{}