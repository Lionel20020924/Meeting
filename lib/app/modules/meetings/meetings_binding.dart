import 'package:get/get.dart';

import 'meetings_controller.dart';

class MeetingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeetingsController>(
      () => MeetingsController(),
    );
  }
}