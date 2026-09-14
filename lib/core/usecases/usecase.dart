// lib/core/usecases/usecase.dart
//
// PURPOSE:
//   Base contract every use case implements.
//   One use case = one action = one call() method.
//
// CHANGE FROM PREVIOUS VERSION:
//   Replaced dartz Either<UserFailure, T> with native Result<T>.

abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Use as Params when the use case takes no input.
class NoParams {
  const NoParams();
}

/// Use for paginated fetches.
class PageParams {
  final int page;
  final int pageSize;
  const PageParams({this.page = 1, this.pageSize = 20});
}

/// Use for search/filter queries.
class SearchParams {
  final String query;
  const SearchParams(this.query);
}
