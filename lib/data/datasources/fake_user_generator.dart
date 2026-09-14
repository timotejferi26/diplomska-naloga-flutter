// lib/data/datasources/fake_user_generator.dart
//
// PURPOSE:
//   Generates a configurable number of realistic User objects.
//   Uses a fixed seed so every benchmark run produces the same dataset —
//   this is critical for reproducible, comparable results.
//
// USED BY:
//   - UserFakeDataSource (pre-seeds its storage on construction)
//   - BenchmarkRunnerScreen (lets user pick N and regenerate)
//   - Integration tests (produces a known dataset to assert against)
//
// SEED BEHAVIOUR:
//   With seed=42 and count=1000, the output is always identical.
//   Change the seed if you want a different but still reproducible dataset.

import 'dart:math';

import 'package:diplomska_naloga/domain/entities/role.dart';
import 'package:diplomska_naloga/domain/entities/user.dart';

class FakeUserGenerator {
  // ── Name pools ────────────────────────────────────────────────
  static const _firstNames = [
    'Ana',
    'Bojan',
    'Cvetka',
    'David',
    'Eva',
    'Filip',
    'Gaja',
    'Hana',
    'Ivan',
    'Jana',
    'Klemen',
    'Lara',
    'Marko',
    'Nina',
    'Oto',
    'Petra',
    'Rok',
    'Sara',
    'Tomaž',
    'Urška',
    'Vita',
    'Žan',
    'Aleš',
    'Barbara',
    'Ciril',
  ];

  static const _lastNames = [
    'Novak',
    'Krajnc',
    'Horvat',
    'Kovač',
    'Zupan',
    'Potočnik',
    'Vidmar',
    'Oblak',
    'Kos',
    'Leban',
    'Petek',
    'Štefan',
    'Golob',
    'Mlakar',
    'Krivec',
    'Lebar',
    'Černe',
    'Bizjak',
    'Turk',
    'Babič',
  ];

  static const _domains = [
    'gmail.com',
    'outlook.com',
    'yahoo.com',
    'benchmark.dev',
    'test.io',
    'example.com',
  ];

  static const _tagPool = [
    'flutter',
    'dart',
    'admin',
    'developer',
    'tester',
    'designer',
    'devops',
    'mobile',
    'backend',
    'frontend',
    'manager',
    'intern',
    'senior',
    'junior',
    'lead',
  ];

  /// Generates [count] User objects.
  ///
  /// [seed] makes output deterministic — same seed = same users every time.
  /// [baseDate] is the createdAt for the first user; each subsequent user
  /// is created 1 hour later, giving a natural time spread.
  static List<User> generate(int count, {int seed = 42, DateTime? baseDate}) {
    final rand = Random(seed);
    final base = baseDate ?? DateTime.parse('2024-01-01T08:00:00Z');

    return List.generate(count, (i) {
      final firstName = _firstNames[rand.nextInt(_firstNames.length)];
      final lastName = _lastNames[rand.nextInt(_lastNames.length)];
      final domain = _domains[rand.nextInt(_domains.length)];
      final name = '$firstName $lastName';
      final email =
          '${firstName.toLowerCase()}.${lastName.toLowerCase()}$i@$domain';
      final tagCount = rand.nextInt(4); // 0–3 tags
      final tags = List.generate(
        tagCount,
        (_) => _tagPool[rand.nextInt(_tagPool.length)],
      ).toSet().toList(); // deduplicate

      final createdAt = base.add(Duration(hours: i));

      return User(
        id: 'fake-$i',
        name: name,
        email: email,
        role: rand.nextDouble() < 0.1 ? Role.admin : Role.user,
        isActive: rand.nextDouble() > 0.1, // 90% active
        createdAt: createdAt,
        updatedAt: createdAt,
        tags: tags,
      );
    });
  }
}
