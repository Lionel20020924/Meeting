import 'package:get/get.dart';

import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    if (index == 1) {
      // Navigate to Record page when "New Meeting" is tapped
      Get.toNamed(Routes.RECORD);
    } else {
      // For other pages, use the index directly
      // Index 0: Meetings, Index 2: Profile
      currentIndex.value = index;
      update(); // Trigger GetBuilder update
    }
  }
  
  @override
  void onInit() {
    super.onInit();
    // Reset to meetings page when returning to home
    currentIndex.value = 0;
  }
}