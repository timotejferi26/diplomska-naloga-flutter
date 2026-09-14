// lib/domain/exceptions/storage_exception.dart
//
// PURPOSE:
//   Thrown by the repository when the datasource fails unexpectedly.
//   Wraps the original error so it isn't lost, but exposes a clean message.
//   Controllers catch this to show a generic "something went wrong" message.

class StorageException implements Exception {
  final String message;
  final Object? cause;

  const StorageException(this.message, {this.cause});

  @override
  String toString() =>
      'StorageException: $message${cause != null ? ' (cause: $cause)' : ''}';
}
