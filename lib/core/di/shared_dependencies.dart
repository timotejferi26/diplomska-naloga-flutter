// lib/core/di/shared_dependencies.dart
//
// PURPOSE:
//   Builds the shared dependency graph that all four library DI setups use.
//   Core services → Datasource → Repository → UseCases.
//   Each library's DI setup calls SharedDependencies.build() and gets back
//   a UserUseCases bundle ready to inject into its controller/notifier.
//
// WHY A SHARED FACTORY:
//   All four libraries test the same domain + data code. If each library
//   wired its own datasource independently, a bug in one setup would
//   corrupt another. The shared factory guarantees all four use identical
//   infrastructure — only the presentation differs.
//
// DATASOURCE SELECTION:
//   - benchmarkMode=true  → UserFakeDataSource (pre-seeded, reproducible)
//   - benchmarkMode=false → UserLocalDataSource (starts empty, user-driven)
//
// USED BY:
//   - libraries/riverpod/di/riverpod_injector.dart
//   - libraries/getx/bindings/user_binding.dart
//   - libraries/provider/di/provider_injector.dart
//   - libraries/watch_it/di/watchit_setup.dart

// ── Bundle returned by SharedDependencies.build() ────────────────────────

import 'package:diplomska_naloga/core/services/benchmark/benchmark_config.dart';
import 'package:diplomska_naloga/core/services/clock_service.dart';
import 'package:diplomska_naloga/core/services/id_generator.dart';
import 'package:diplomska_naloga/core/services/logger_service.dart';
import 'package:diplomska_naloga/data/datasources/user_datasource_interface.dart';
import 'package:diplomska_naloga/data/datasources/user_fake_datasource.dart';
import 'package:diplomska_naloga/data/datasources/user_local_datasource.dart';
import 'package:diplomska_naloga/data/repositories/user_repository_impl.dart';
import 'package:diplomska_naloga/domain/repositories/user_repository.dart';
import 'package:diplomska_naloga/domain/usecases/add_user_usecase.dart';
import 'package:diplomska_naloga/domain/usecases/delete_user_usecase.dart';
import 'package:diplomska_naloga/domain/usecases/get_users_usecase.dart';
import 'package:diplomska_naloga/domain/usecases/search_user_usecase.dart';
import 'package:diplomska_naloga/domain/usecases/update_user_usecase.dart';
import 'package:diplomska_naloga/domain/validators/user_validator.dart';

/// All five use cases in one object — passed to each library's controller.
class UserUseCases {
  final GetUsersUseCase getUsers;
  final AddUserUseCase addUser;
  final UpdateUserUseCase updateUser;
  final DeleteUserUseCase deleteUser;
  final SearchUsersUseCase searchUsers;

  const UserUseCases({
    required this.getUsers,
    required this.addUser,
    required this.updateUser,
    required this.deleteUser,
    required this.searchUsers,
  });
}

// ── Factory ───────────────────────────────────────────────────────────────

class SharedDependencies {
  SharedDependencies._();

  /// Builds the full dependency graph and returns the use case bundle.
  ///
  /// [benchmarkMode] = true  → pre-seeded FakeDataSource
  /// [benchmarkMode] = false → empty LocalDataSource
  /// [loggerOverride] → inject a custom logger (e.g. SilentLogger for perf runs)
  static UserUseCases build({
    bool benchmarkMode = true,
    ILogger? loggerOverride,
  }) {
    final config = BenchmarkConfig.instance;
    final logger = loggerOverride ?? const ConsoleLogger();

    // ── Services ──────────────────────────────────────────────
    const clock = SystemClockService();
    final idGen = UuidGenerator();
    const validator = DefaultUserValidator();

    // ── Datasource ────────────────────────────────────────────
    final IUserDataSource dataSource = benchmarkMode
        ? UserFakeDataSource(
            count: config.datasetSize,
            seed: config.generatorSeed,
            logger: logger,
          )
        : UserLocalDataSource(logger: logger);

    // ── Repository ────────────────────────────────────────────
    final IUserRepository repository = UserRepositoryImpl(
      dataSource: dataSource,
      idGenerator: idGen,
      clock: clock,
      validator: validator,
      logger: logger,
    );

    // ── Use Cases ─────────────────────────────────────────────
    return UserUseCases(
      getUsers: GetUsersUseCase(repository),
      addUser: AddUserUseCase(repository),
      updateUser: UpdateUserUseCase(repository),
      deleteUser: DeleteUserUseCase(repository),
      searchUsers: SearchUsersUseCase(repository),
    );
  }
}
