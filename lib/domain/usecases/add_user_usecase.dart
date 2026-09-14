// lib/domain/usecases/add_user_usecase.dart
// BENCHMARK EVENT: 'add_user'
import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/repositories/user_repository.dart';

class AddUserParams {
  final String name;
  final String email;
  final List<String> tags;
  const AddUserParams({
    required this.name,
    required this.email,
    required this.tags,
  });
}

class AddUserUseCase implements UseCase<User, AddUserParams> {
  final IUserRepository _repository;
  const AddUserUseCase(this._repository);

  @override
  Future<User> call(AddUserParams params) => _repository.createUser(
    name: params.name,
    email: params.email,
    tags: params.tags,
  );
}
