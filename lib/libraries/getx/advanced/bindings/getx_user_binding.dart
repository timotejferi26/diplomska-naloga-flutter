// lib/libraries/getx/bindings/getx_user_binding.dart
//
// Registers the shared UserUseCases bundle (built via SharedDependencies)
// into Get's service locator, plus the controller that resolves it via Get.find.
// Controller uses lazyPut (lazy singleton); the bundle uses permanent: false.

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/libraries/getx/advanced/controllers/getx_user_controller.dart';
import 'package:get/get.dart';

class GetXUserBinding extends Bindings {
  @override
  void dependencies() {
    // Build entire dep graph via shared factory
    final useCases = SharedDependencies.build(benchmarkMode: true);

    // Register use case bundle
    Get.put<UserUseCases>(useCases, permanent: false);

    // Controller as factory — new instance per navigation
    Get.lazyPut<GetXUserController>(
      () => GetXUserController(useCases: Get.find<UserUseCases>()),
    );
  }
}
