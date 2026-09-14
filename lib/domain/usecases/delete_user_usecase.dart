// lib/domain/usecases/delete_user_usecase.dart
// BENCHMARK EVENT: 'delete_user'

import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/repositories/user_repository.dart';

class DeleteUserUseCase implements UseCase<void, String> {
  final IUserRepository _repository;
  const DeleteUserUseCase(this._repository);

  @override
  Future<void> call(String id) => _repository.deleteUser(id);
}
