import 'package:get/get.dart';

import 'meeting_detail_controller.dart';

class MeetingDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeetingDetailController>(
      () => MeetingDetailController(),
    );
  }
}