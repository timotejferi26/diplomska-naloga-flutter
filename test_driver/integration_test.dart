// test_driver/integration_test.dart
//
// Standard driver entry point — no changes needed here.
// Run with: flutter drive --driver=test_driver/integration_test.dart
//                         --target=integration_test/default_benchmark_test.dart or integration_test/advanced_benchmark_test.dart
//                         --profile   ← always run in profile mode for realistic timing

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
