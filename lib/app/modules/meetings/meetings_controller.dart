import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';

class MeetingsController extends GetxController {
  final meetings = <Map<String, String>>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMeetings();
  }

  Future<void> loadMeetings() async {
    isLoading.value = true;
    
    // TODO: Load actual meetings from database
    await Future.delayed(const Duration(seconds: 1));
    
    meetings.value = [
      {
        'id': '1',
        'title': 'Team Standup',
        'date': '2024-01-20 09:00',
        'participants': '5',
      },
      {
        'id': '2',
        'title': 'Client Review',
        'date': '2024-01-20 14:00',
        'participants': '3',
      },
      {
        'id': '3',
        'title': 'Sprint Planning',
        'date': '2024-01-21 10:00',
        'participants': '8',
      },
      {
        'id': '4',
        'title': 'Design Review',
        'date': '2024-01-19 15:30',
        'participants': '4',
      },
    ];
    
    isLoading.value = false;
  }

  Future<void> refreshMeetings() async {
    await loadMeetings();
  }

  bool isToday(String dateString) {
    // Simple check - in real app, parse and compare dates properly
    final today = DateTime.now();
    return dateString.contains('2024-01-20'); // Mock today's date
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

  void goToMeetingDetail(Map<String, String> meeting) {
    Get.toNamed(Routes.MEETING_DETAIL, arguments: meeting);
  }

  void startRecording() {
    Get.toNamed(Routes.RECORD);
  }

  void goToProfile() {
    Get.toNamed(Routes.PROFILE);
  }
}