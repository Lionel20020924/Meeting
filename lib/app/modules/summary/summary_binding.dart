import 'package:get/get.dart';

import '../meetings/meetings_controller.dart';
import 'summary_controller.dart';

class SummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SummaryController>(
      () => SummaryController(),
    );
    
    // Ensure MeetingsController is available
    if (!Get.isRegistered<MeetingsController>()) {
      Get.lazyPut<MeetingsController>(
        () => MeetingsController(),
      );
    }
  }
}