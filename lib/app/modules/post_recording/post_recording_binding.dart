import 'package:get/get.dart';

import 'post_recording_controller.dart';

class PostRecordingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostRecordingController>(
      () => PostRecordingController(),
    );
  }
}