// lib/domain/usecases/search_users_usecase.dart
// BENCHMARK EVENT: 'search_query'

import 'package:diplomska_naloga/core/usecases/usecase.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';
import 'package:diplomska_naloga/domain/repositories/user_repository.dart';

class SearchUsersUseCase implements UseCase<List<User>, SearchParams> {
  final IUserRepository _repository;
  const SearchUsersUseCase(this._repository);

  @override
  Future<List<User>> call(SearchParams params) =>
      _repository.filterUsers(params.query);
}
