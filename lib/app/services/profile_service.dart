import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class ProfileService {
  static const String _profileFile = 'user_profile.json';

  // Default profile data
  static const Map<String, dynamic> defaultProfile = {
    'name': '',
    'email': '',
    'phone': '',
    'company': '',
    'position': '',
    'department': '',
    'bio': '',
    'meetingPreferences': {
      'defaultDuration': 30,
      'autoTranscribe': true,
      'autoSummarize': true,
      'language': 'zh',
    },
  };

  /// Get the application documents directory
  static Future<Directory> get _documentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Get the profile file path
  static Future<File> get _profileFilePath async {
    final dir = await _documentsDirectory;
    final meetingDir = Directory('${dir.path}/meeting_app');
    if (!await meetingDir.exists()) {
      await meetingDir.create(recursive: true);
    }
    return File('${meetingDir.path}/$_profileFile');
  }

  // Load user profile
  static Future<Map<String, dynamic>> loadProfile() async {
    try {
      final file = await _profileFilePath;
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          return Map<String, dynamic>.from(jsonDecode(contents));
        }
      }
      
      return Map<String, dynamic>.from(defaultProfile);
    } catch (e) {
      return Map<String, dynamic>.from(defaultProfile);
    }
  }

  // Save user profile
  static Future<bool> saveProfile(Map<String, dynamic> profile) async {
    try {
      final file = await _profileFilePath;
      final profileString = jsonEncode(profile);
      await file.writeAsString(profileString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update specific field
  static Future<bool> updateProfileField(String field, dynamic value) async {
    try {
      final profile = await loadProfile();
      
      // Handle nested fields (e.g., 'meetingPreferences.defaultDuration')
      if (field.contains('.')) {
        final parts = field.split('.');
        Map<String, dynamic> current = profile;
        for (int i = 0; i < parts.length - 1; i++) {
          if (current[parts[i]] == null) {
            current[parts[i]] = {};
          }
          current = current[parts[i]];
        }
        current[parts.last] = value;
      } else {
        profile[field] = value;
      }
      
      return await saveProfile(profile);
    } catch (e) {
      return false;
    }
  }

  // Get user initials for avatar
  static String getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // Generate avatar color based on name
  static int getAvatarColor(String name) {
    if (name.isEmpty) return 0xFF2196F3; // Default blue
    
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // List of professional colors
    final colors = [
      0xFF2196F3, // Blue
      0xFF4CAF50, // Green
      0xFF9C27B0, // Purple
      0xFFFF9800, // Orange
      0xFF009688, // Teal
      0xFF795548, // Brown
      0xFF607D8B, // Blue Grey
      0xFFE91E63, // Pink
    ];
    
    return colors[hash.abs() % colors.length];
  }

  // Clear profile (for logout)
  static Future<bool> clearProfile() async {
    try {
      final file = await _profileFilePath;
      
      // Try to delete the file if it exists
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (deleteError) {
          // If delete fails, try to overwrite with empty data
          if (Get.isLogEnable) {
            Get.log('Failed to delete profile file: $deleteError');
          }
          await file.writeAsString(jsonEncode(defaultProfile));
        }
      }
      
      // Also try to clear the parent directory if empty
      try {
        final dir = file.parent;
        if (await dir.exists()) {
          final contents = await dir.list().toList();
          if (contents.isEmpty) {
            await dir.delete();
          }
        }
      } catch (dirError) {
        // Ignore directory cleanup errors
        if (Get.isLogEnable) {
          Get.log('Directory cleanup failed: $dirError');
        }
      }
      
      return true;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error clearing profile: $e');
      }
      // Try alternative approach - overwrite with default data
      try {
        final file = await _profileFilePath;
        await file.writeAsString(jsonEncode(defaultProfile));
        return true;
      } catch (fallbackError) {
        if (Get.isLogEnable) {
          Get.log('Fallback clear also failed: $fallbackError');
        }
        return false;
      }
    }
  }

  // Get meeting statistics
  static Future<Map<String, int>> getMeetingStats() async {
    try {
      // This would normally query the meetings data
      // For now, return mock data
      return {
        'total': 0,
        'thisWeek': 0,
        'thisMonth': 0,
        'averageDuration': 0,
      };
    } catch (e) {
      return {
        'total': 0,
        'thisWeek': 0,
        'thisMonth': 0,
        'averageDuration': 0,
      };
    }
  }
}