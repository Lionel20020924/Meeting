import 'package:get/get.dart';

import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    if (index == 1) {
      // Navigate to Record page when "New Meeting" is tapped
      Get.toNamed(Routes.RECORD);
    } else {
      // Update index for other pages (adjust for the missing middle page)
      currentIndex.value = index > 1 ? index - 1 : index;
    }
  }
}