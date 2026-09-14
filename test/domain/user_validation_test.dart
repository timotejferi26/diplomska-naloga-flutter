import 'package:diplomska_naloga/core/services/clock_service.dart';
import 'package:diplomska_naloga/core/services/id_generator.dart';
import 'package:diplomska_naloga/core/services/logger_service.dart';
import 'package:diplomska_naloga/data/datasources/fake_user_generator.dart';
import 'package:diplomska_naloga/data/datasources/user_fake_datasource.dart';
import 'package:diplomska_naloga/data/repositories/user_repository_impl.dart';
import 'package:diplomska_naloga/domain/validators/user_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = DefaultUserValidator();

  test('all generated users can be submitted without changing their email', () {
    final users = FakeUserGenerator.generate(5000);

    for (final user in users) {
      validator.validateUpdate(
        id: user.id,
        name: user.name,
        email: user.email,
        tags: user.tags,
      );
    }
  });

  test('editing a generated user persists the updated data', () async {
    final dataSource = UserFakeDataSource(
      count: 5000,
      logger: const SilentLogger(),
    );
    final repository = UserRepositoryImpl(
      dataSource: dataSource,
      idGenerator: SequentialIdGenerator(),
      clock: FixedClockService.benchmark(),
      validator: validator,
      logger: const SilentLogger(),
    );
    final users = await dataSource.getAllUsers(pageSize: 5000);
    final existing = users.firstWhere(
      (user) => RegExp(r'[^\x00-\x7F]').hasMatch(user.email),
    );

    final updated = await repository.updateUser(
      existing.copyWith(name: 'Posodobljen uporabnik'),
    );
    final stored = (await dataSource.filterUsers(
      'Posodobljen uporabnik',
    )).single;

    expect(updated.name, 'Posodobljen uporabnik');
    expect(updated.email, existing.email);
    expect(stored, updated);
  });
}
