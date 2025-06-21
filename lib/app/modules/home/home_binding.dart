import 'package:get/get.dart';

import '../meetings/meetings_controller.dart';
import '../profile/profile_controller.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
    Get.lazyPut<MeetingsController>(
      () => MeetingsController(),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
  }
}