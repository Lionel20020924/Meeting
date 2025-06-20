import 'package:get/get.dart';

import '../../routes/app_pages.dart';

class MeetingDetailController extends GetxController {
  late Map<String, String> meeting;

  @override
  void onInit() {
    super.onInit();
    meeting = Get.arguments ?? {};
  }

  void viewFullSummary() {
    Get.toNamed(Routes.SUMMARY, arguments: meeting);
  }
}