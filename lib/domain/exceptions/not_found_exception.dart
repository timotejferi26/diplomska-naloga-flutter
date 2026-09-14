// lib/domain/exceptions/not_found_exception.dart
//
// PURPOSE:
//   Thrown by the repository when a user id does not exist in storage.
//   Controllers catch this specifically to show a "not found" message.

class NotFoundException implements Exception {
  final String id;
  const NotFoundException(this.id);

  @override
  String toString() => 'NotFoundException: no user with id "$id"';
}
