import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';

class ProfileController extends GetxController {
  // Profile data
  final profileData = <String, dynamic>{}.obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  final isSaving = false.obs;
  
  // Meeting statistics
  final totalMeetings = 0.obs;
  final weeklyMeetings = 0.obs;
  final monthlyMeetings = 0.obs;
  final averageDuration = 0.obs;
  
  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final companyController = TextEditingController();
  final positionController = TextEditingController();
  final departmentController = TextEditingController();
  final bioController = TextEditingController();
  
  // Form key
  final formKey = GlobalKey<FormState>();
  
  // Avatar
  String get userName => profileData['name'] ?? '';
  String get userEmail => profileData['email'] ?? '';
  String get userInitials => ProfileService.getUserInitials(userName);
  Color get avatarColor {
    try {
      return Color(ProfileService.getAvatarColor(userName));
    } catch (e) {
      return Colors.blue; // Default color if parsing fails
    }
  }
  
  @override
  void onInit() {
    super.onInit();
    if (Get.isLogEnable) {
      Get.log('ProfileController onInit called');
    }
    loadProfile();
    loadMeetingStats();
  }
  
  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    companyController.dispose();
    positionController.dispose();
    departmentController.dispose();
    bioController.dispose();
    super.onClose();
  }
  
  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      final profile = await ProfileService.loadProfile();
      
      // Ensure meetingPreferences exists
      if (profile['meetingPreferences'] == null) {
        profile['meetingPreferences'] = {
          'defaultDuration': 30,
          'autoTranscribe': true,
          'autoSummarize': true,
          'language': 'zh',
        };
      }
      
      profileData.value = profile;
      
      // Update controllers with loaded data
      nameController.text = profile['name'] ?? '';
      emailController.text = profile['email'] ?? '';
      phoneController.text = profile['phone'] ?? '';
      companyController.text = profile['company'] ?? '';
      positionController.text = profile['position'] ?? '';
      departmentController.text = profile['department'] ?? '';
      bioController.text = profile['bio'] ?? '';
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error loading profile: $e');
      }
      // Set default profile data on error
      profileData.value = Map<String, dynamic>.from(ProfileService.defaultProfile);
      Get.snackbar(
        'Error',
        'Failed to load profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadMeetingStats() async {
    try {
      // Load actual meetings from storage
      final meetings = await StorageService.loadMeetings();
      
      // Calculate statistics
      totalMeetings.value = meetings.length;
      
      // Calculate weekly meetings
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      weeklyMeetings.value = meetings.where((meeting) {
        try {
          final dateStr = meeting['date']?.toString();
          if (dateStr == null || dateStr.isEmpty) return false;
          final meetingDate = DateTime.parse(dateStr);
          return meetingDate.isAfter(weekStart);
        } catch (e) {
          return false;
        }
      }).length;
      
      // Calculate monthly meetings
      final monthStart = DateTime(now.year, now.month, 1);
      monthlyMeetings.value = meetings.where((meeting) {
        try {
          final dateStr = meeting['date']?.toString();
          if (dateStr == null || dateStr.isEmpty) return false;
          final meetingDate = DateTime.parse(dateStr);
          return meetingDate.isAfter(monthStart);
        } catch (e) {
          return false;
        }
      }).length;
      
      // Calculate average duration
      if (meetings.isNotEmpty) {
        int totalSeconds = 0;
        int validMeetings = 0;
        for (final meeting in meetings) {
          try {
            final duration = meeting['duration']?.toString() ?? '00:00';
            final parts = duration.split(':');
            if (parts.length >= 2) {
              totalSeconds += int.parse(parts[0]) * 60 + int.parse(parts[1]);
              validMeetings++;
            }
          } catch (e) {
            // Skip invalid duration
          }
        }
        averageDuration.value = validMeetings > 0 ? totalSeconds ~/ validMeetings : 0;
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error loading meeting stats: $e');
      }
      // Set default values on error
      totalMeetings.value = 0;
      weeklyMeetings.value = 0;
      monthlyMeetings.value = 0;
      averageDuration.value = 0;
    }
  }
  
  void toggleEdit() {
    isEditing.value = !isEditing.value;
    
    // Reset form if canceling edit
    if (!isEditing.value) {
      nameController.text = profileData['name'] ?? '';
      emailController.text = profileData['email'] ?? '';
      phoneController.text = profileData['phone'] ?? '';
      companyController.text = profileData['company'] ?? '';
      positionController.text = profileData['position'] ?? '';
      departmentController.text = profileData['department'] ?? '';
      bioController.text = profileData['bio'] ?? '';
    }
  }
  
  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    
    try {
      isSaving.value = true;
      
      // Update profile data from controllers
      profileData['name'] = nameController.text.trim();
      profileData['email'] = emailController.text.trim();
      profileData['phone'] = phoneController.text.trim();
      profileData['company'] = companyController.text.trim();
      profileData['position'] = positionController.text.trim();
      profileData['department'] = departmentController.text.trim();
      profileData['bio'] = bioController.text.trim();
      
      // Save to storage
      final success = await ProfileService.saveProfile(profileData);
      
      if (success) {
        isEditing.value = false;
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to save profile');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }
  
  void updatePreference(String key, dynamic value) async {
    try {
      // Ensure meetingPreferences exists
      if (profileData['meetingPreferences'] == null) {
        profileData['meetingPreferences'] = {};
      }
      
      await ProfileService.updateProfileField('meetingPreferences.$key', value);
      profileData['meetingPreferences'][key] = value;
      profileData.refresh();
      
      Get.snackbar(
        'Success',
        'Preference updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error updating preference: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to update preference',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
          TextButton(
            onPressed: () {
              // Close dialog first
              Get.back();
              // Call the actual logout process
              _performLogout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performLogout() async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );
      
      // Clear profile data
      final cleared = await ProfileService.clearProfile();
      if (!cleared) {
        throw Exception('Failed to clear profile data');
      }
      
      // Clear any cached data in memory
      profileData.clear();
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      companyController.clear();
      positionController.clear();
      departmentController.clear();
      bioController.clear();
      
      // Reset statistics
      totalMeetings.value = 0;
      weeklyMeetings.value = 0;
      monthlyMeetings.value = 0;
      averageDuration.value = 0;
      
      // Small delay to ensure everything is cleared
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Close loading dialog and navigate to login
      if (Get.isDialogOpen ?? false) {
        Get.back(); // Close loading dialog
      }
      
      // Navigate to login page
      Get.offAllNamed(Routes.LOGIN);
      
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      if (Get.isLogEnable) {
        Get.log('Logout error: $e');
      }
      
      // Show error message
      Get.snackbar(
        'Logout Failed',
        'An error occurred while logging out. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    return '$minutes min';
  }
  
  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }
  
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  
  String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty && !GetUtils.isPhoneNumber(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}