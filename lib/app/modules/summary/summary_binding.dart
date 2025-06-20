import 'package:get/get.dart';

import 'summary_controller.dart';

class SummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SummaryController>(
      () => SummaryController(),
    );
  }
}