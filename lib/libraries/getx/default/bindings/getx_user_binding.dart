// lib/libraries/getx/bindings/getx_user_binding.dart
//
// Registers all dependencies into Get's service locator.
// Registers IUserRepository (interface) not the concrete class.
// Controller is registered as a factory so it is recreated fresh each run.

import 'package:diplomska_naloga/core/di/shared_dependencies.dart';
import 'package:diplomska_naloga/libraries/getx/default/controllers/getx_user_controller.dart';
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
