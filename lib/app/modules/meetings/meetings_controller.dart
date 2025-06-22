import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';

class MeetingsController extends GetxController {
  final meetings = <Map<String, dynamic>>[].obs;
  final filteredMeetings = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  
  // Selection mode
  final isSelectionMode = false.obs;
  final selectedMeetings = <String>{}.obs;
  
  // Search and filter
  final TextEditingController searchController = TextEditingController();
  final currentFilter = 'all'.obs;
  final currentSort = 'date_desc'.obs;

  @override
  void onInit() {
    super.onInit();
    loadMeetings();
  }

  @override
  void onReady() {
    super.onReady();
    // Reload meetings when the controller is ready (useful when navigating back)
    loadMeetings();
  }
  
  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadMeetings() async {
    isLoading.value = true;
    
    try {
      // Load actual meetings from storage
      final storedMeetings = await StorageService.loadMeetings();
      meetings.value = storedMeetings;
      _applyFiltersAndSort();
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error loading meetings: $e');
      }
      // Keep empty list if error occurs
      meetings.value = [];
      filteredMeetings.value = [];
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

  Future<void> deleteMeeting(Map<String, dynamic> meeting) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this meeting?'),
            const SizedBox(height: 16),
            Text(
              meeting['title'] ?? 'Untitled Meeting',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. The audio recording will also be deleted.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // Delete from storage (this also deletes the audio file)
        await StorageService.deleteMeeting(meeting['id']);

        // Remove from local list
        meetings.removeWhere((m) => m['id'] == meeting['id']);

        // Close loading dialog
        Get.back();

        // Show success message
        Get.snackbar(
          'Success',
          'Meeting deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        // Close loading dialog
        Get.back();

        // Show error message
        Get.snackbar(
          'Error',
          'Failed to delete meeting: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Selection mode methods
  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedMeetings.clear();
    }
  }

  void toggleMeetingSelection(String meetingId) {
    if (selectedMeetings.contains(meetingId)) {
      selectedMeetings.remove(meetingId);
    } else {
      selectedMeetings.add(meetingId);
    }
  }

  void selectAll() {
    selectedMeetings.clear();
    selectedMeetings.addAll(filteredMeetings.map((m) => m['id'].toString()));
  }

  void deselectAll() {
    selectedMeetings.clear();
  }

  Future<void> deleteSelectedMeetings() async {
    if (selectedMeetings.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Selected Meetings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${selectedMeetings.length} meeting${selectedMeetings.length > 1 ? 's' : ''}?'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. All audio recordings will also be deleted.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete ${selectedMeetings.length} Meeting${selectedMeetings.length > 1 ? 's' : ''}'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // Delete each selected meeting
        for (final meetingId in selectedMeetings) {
          await StorageService.deleteMeeting(meetingId);
        }

        // Remove from local list
        meetings.removeWhere((m) => selectedMeetings.contains(m['id'].toString()));

        // Clear selection and exit selection mode
        selectedMeetings.clear();
        isSelectionMode.value = false;

        // Close loading dialog
        Get.back();

        // Show success message
        Get.snackbar(
          'Success',
          'Selected meetings deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        // Close loading dialog
        Get.back();

        // Show error message
        Get.snackbar(
          'Error',
          'Failed to delete meetings: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
  
  // Search and filter methods
  void searchMeetings(String query) {
    searchQuery.value = query;
    _applyFiltersAndSort();
  }
  
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFiltersAndSort();
  }
  
  void setFilter(String filter) {
    currentFilter.value = filter;
    _applyFiltersAndSort();
  }
  
  void setSortOrder(String sort) {
    currentSort.value = sort;
    _applyFiltersAndSort();
  }
  
  void _applyFiltersAndSort() {
    var filtered = meetings.toList();
    
    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((meeting) {
        final title = meeting['title']?.toString().toLowerCase() ?? '';
        final transcription = meeting['transcription']?.toString().toLowerCase() ?? '';
        final query = searchQuery.value.toLowerCase();
        return title.contains(query) || transcription.contains(query);
      }).toList();
    }
    
    // Apply date filter
    final now = DateTime.now();
    switch (currentFilter.value) {
      case 'today':
        filtered = filtered.where((meeting) => isToday(meeting['date']?.toString() ?? '')).toList();
        break;
      case 'week':
        filtered = filtered.where((meeting) {
          try {
            final date = DateTime.parse(meeting['date']?.toString() ?? '');
            final difference = now.difference(date).inDays;
            return difference >= 0 && difference <= 7;
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 'month':
        filtered = filtered.where((meeting) {
          try {
            final date = DateTime.parse(meeting['date']?.toString() ?? '');
            return date.year == now.year && date.month == now.month;
          } catch (e) {
            return false;
          }
        }).toList();
        break;
    }
    
    // Apply sorting
    switch (currentSort.value) {
      case 'date_asc':
        filtered.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['date']?.toString() ?? '');
            final dateB = DateTime.parse(b['date']?.toString() ?? '');
            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'date_desc':
        filtered.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['date']?.toString() ?? '');
            final dateB = DateTime.parse(b['date']?.toString() ?? '');
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'title_asc':
        filtered.sort((a, b) {
          final titleA = a['title']?.toString() ?? '';
          final titleB = b['title']?.toString() ?? '';
          return titleA.compareTo(titleB);
        });
        break;
      case 'duration_desc':
        filtered.sort((a, b) {
          final durationA = _parseDuration(a['duration']?.toString() ?? '00:00');
          final durationB = _parseDuration(b['duration']?.toString() ?? '00:00');
          return durationB.compareTo(durationA);
        });
        break;
    }
    
    filteredMeetings.value = filtered;
  }
  
  int _parseDuration(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length >= 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return minutes * 60 + seconds;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 0;
  }
  
  String getRelativeTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
  
  int getWeeklyMeetingsCount() {
    final now = DateTime.now();
    return meetings.where((meeting) {
      try {
        final date = DateTime.parse(meeting['date']?.toString() ?? '');
        final difference = now.difference(date).inDays;
        return difference >= 0 && difference <= 7;
      } catch (e) {
        return false;
      }
    }).length;
  }
  
  String getTotalHours() {
    int totalSeconds = 0;
    for (final meeting in meetings) {
      totalSeconds += _parseDuration(meeting['duration']?.toString() ?? '00:00');
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }
}