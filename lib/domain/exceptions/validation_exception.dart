// lib/domain/validators/validation_exception.dart
//
// PURPOSE:
//   Exception thrown synchronously by IUserValidator implementations.
//   UserRepositoryImpl catches this and converts it to a ValidationFailure
//   so that use cases can return Either.left(ValidationFailure(...)).
//
// WHY AN EXCEPTION AND NOT A FAILURE:
//   Validators are synchronous — they can't return Future<Either<...>>.
//   Throwing an exception is the idiomatic Dart way to signal a
//   synchronous error from a void method. The repository boundary
//   converts it into the Either pattern used everywhere else.

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
