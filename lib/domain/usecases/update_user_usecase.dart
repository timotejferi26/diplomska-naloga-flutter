// lib/domain/usecases/update_user_usecase.dart
// BENCHMARK EVENT: 'edit_user'

import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/repositories/user_repository.dart';

class UpdateUserUseCase implements UseCase<User, User> {
  final IUserRepository _repository;
  const UpdateUserUseCase(this._repository);

  @override
  Future<User> call(User user) => _repository.updateUser(user);
}
