import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';

class MeetingsController extends GetxController {
  final meetings = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMeetings();
  }

  Future<void> loadMeetings() async {
    isLoading.value = true;
    
    try {
      // Load actual meetings from storage
      final storedMeetings = await StorageService.loadMeetings();
      meetings.value = storedMeetings;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error loading meetings: $e');
      }
      // Keep empty list if error occurs
      meetings.value = [];
    }
    
    isLoading.value = false;
  }

  Future<void> refreshMeetings() async {
    await loadMeetings();
  }

  bool isToday(String dateString) {
    try {
      final meetingDate = DateTime.parse(dateString);
      final today = DateTime.now();
      return meetingDate.year == today.year &&
             meetingDate.month == today.month &&
             meetingDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  void showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Search Meetings'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter meeting title...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => searchQuery.value = value,
          onSubmitted: (value) {
            Get.back();
            if (value.isNotEmpty) {
              // TODO: Implement search functionality
              Get.snackbar(
                'Search',
                'Searching for: $value',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // TODO: Implement search
              if (searchQuery.value.isNotEmpty) {
                Get.snackbar(
                  'Search',
                  'Searching for: ${searchQuery.value}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void goToMeetingDetail(Map<String, dynamic> meeting) {
    Get.toNamed(Routes.SUMMARY, arguments: meeting);
  }

  void startRecording() {
    Get.toNamed(Routes.RECORD);
  }

  void addNewMeeting(Map<String, dynamic> meeting) {
    // Add the new meeting at the beginning of the list
    meetings.insert(0, meeting);
    // Meeting is already persisted by the record controller
  }
  
  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              // Navigate to login page and clear all routes
              Get.offAllNamed(Routes.LOGIN);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  void goToSettings() {
    // TODO: Navigate to settings page when implemented
    Get.snackbar(
      'Settings',
      'Settings page coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}