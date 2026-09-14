// lib/domain/usecases/get_users_usecase.dart
// BENCHMARK EVENT: 'load_N'
import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/repositories/user_repository.dart';

class GetUsersUseCase implements UseCase<List<User>, PageParams> {
  final IUserRepository _repository;
  const GetUsersUseCase(this._repository);

  @override
  Future<List<User>> call(PageParams params) =>
      _repository.getAllUsers(page: params.page, pageSize: params.pageSize);
}
