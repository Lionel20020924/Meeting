import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String _meetingsFile = 'meetings.json';
  static const String _audioFolder = 'recordings';
  
  /// Get the application documents directory
  static Future<Directory> get _documentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Get the meetings storage directory
  static Future<Directory> get _meetingsDirectory async {
    final dir = await _documentsDirectory;
    final meetingsDir = Directory('${dir.path}/meeting_app');
    if (!await meetingsDir.exists()) {
      await meetingsDir.create(recursive: true);
    }
    return meetingsDir;
  }
  
  /// Get the audio recordings directory
  static Future<Directory> get _audioDirectory async {
    final meetingsDir = await _meetingsDirectory;
    final audioDir = Directory('${meetingsDir.path}/$_audioFolder');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }
  
  /// Save audio file to permanent storage
  static Future<String> saveAudioFile(String tempPath) async {
    try {
      final audioDir = await _audioDirectory;
      final tempFile = File(tempPath);
      
      if (!await tempFile.exists()) {
        throw Exception('Temporary audio file not found');
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${audioDir.path}/recording_$timestamp.wav';
      
      // Copy file to permanent location
      await tempFile.copy(newPath);
      
      return newPath;
    } catch (e) {
      throw Exception('Failed to save audio file: $e');
    }
  }
  
  /// Save meeting data to JSON file
  static Future<void> saveMeeting(Map<String, dynamic> meeting) async {
    try {
      final meetingsDir = await _meetingsDirectory;
      final file = File('${meetingsDir.path}/$_meetingsFile');
      
      // Load existing meetings
      List<Map<String, dynamic>> meetings = await loadMeetings();
      
      // Add sync metadata
      meeting['localCreatedAt'] = DateTime.now().toIso8601String();
      meeting['syncStatus'] = 'pending';
      
      // Add new meeting
      meetings.insert(0, meeting);
      
      // Save to file
      await file.writeAsString(jsonEncode(meetings));
    } catch (e) {
      throw Exception('Failed to save meeting: $e');
    }
  }
  
  /// Load all meetings from JSON file
  static Future<List<Map<String, dynamic>>> loadMeetings() async {
    try {
      final meetingsDir = await _meetingsDirectory;
      final file = File('${meetingsDir.path}/$_meetingsFile');
      
      if (!await file.exists()) {
        return [];
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content) as List;
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      // Return empty list if error occurs
      return [];
    }
  }
  
  /// Delete a meeting and its audio file
  static Future<void> deleteMeeting(String meetingId) async {
    try {
      // Ensure meetingId is a string for consistent comparison
      final idToDelete = meetingId.toString();
      
      // Load meetings
      List<Map<String, dynamic>> meetings = await loadMeetings();
      
      // Find and remove the meeting (ensure consistent ID comparison)
      final meetingIndex = meetings.indexWhere((m) => m['id'].toString() == idToDelete);
      if (meetingIndex == -1) {
        throw Exception('Meeting with ID $idToDelete not found');
      }
      
      final meeting = meetings[meetingIndex];
      
      // Delete audio file if exists
      if (meeting['audioPath'] != null && meeting['audioPath'].toString().isNotEmpty) {
        try {
          final audioFile = File(meeting['audioPath']);
          if (await audioFile.exists()) {
            await audioFile.delete();
          }
        } catch (audioError) {
          // Log audio deletion error but don't fail the entire operation
          // In a production app, you would use a proper logging framework
          // For now, we'll just ignore the audio deletion error
        }
      }
      
      // Remove from list
      meetings.removeAt(meetingIndex);
      
      // Save updated meetings list
      final meetingsDir = await _meetingsDirectory;
      final file = File('${meetingsDir.path}/$_meetingsFile');
      await file.writeAsString(jsonEncode(meetings));
      
    } catch (e) {
      throw Exception('Failed to delete meeting: $e');
    }
  }
  
  /// Update an existing meeting
  static Future<void> updateMeeting(Map<String, dynamic> updatedMeeting) async {
    try {
      List<Map<String, dynamic>> meetings = await loadMeetings();
      
      final index = meetings.indexWhere((m) => m['id'] == updatedMeeting['id']);
      if (index != -1) {
        // Update sync metadata
        updatedMeeting['localUpdatedAt'] = DateTime.now().toIso8601String();
        if (updatedMeeting['syncStatus'] == 'synced') {
          updatedMeeting['syncStatus'] = 'pending';
        }
        
        meetings[index] = updatedMeeting;
        
        final meetingsDir = await _meetingsDirectory;
        final file = File('${meetingsDir.path}/$_meetingsFile');
        await file.writeAsString(jsonEncode(meetings));
      }
    } catch (e) {
      throw Exception('Failed to update meeting: $e');
    }
  }
  
  /// Get the total size of stored recordings
  static Future<int> getStorageSize() async {
    try {
      final audioDir = await _audioDirectory;
      int totalSize = 0;
      
      await for (final file in audioDir.list()) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  /// Update sync status for a meeting
  static Future<void> updateMeetingSyncStatus(String meetingId, String syncStatus) async {
    try {
      List<Map<String, dynamic>> meetings = await loadMeetings();
      
      final index = meetings.indexWhere((m) => m['id'].toString() == meetingId);
      if (index != -1) {
        meetings[index]['syncStatus'] = syncStatus;
        meetings[index]['lastSyncedAt'] = DateTime.now().toIso8601String();
        
        final meetingsDir = await _meetingsDirectory;
        final file = File('${meetingsDir.path}/$_meetingsFile');
        await file.writeAsString(jsonEncode(meetings));
      }
    } catch (e) {
      // Don't throw, just log the error silently
    }
  }
  
  /// Get meetings that need syncing
  static Future<List<Map<String, dynamic>>> getMeetingsNeedingSync() async {
    try {
      final meetings = await loadMeetings();
      return meetings.where((m) => 
        m['syncStatus'] == null || 
        m['syncStatus'] == 'pending' || 
        m['syncStatus'] == 'error'
      ).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Clear all stored data (use with caution)
  static Future<void> clearAllData() async {
    try {
      final meetingsDir = await _meetingsDirectory;
      if (await meetingsDir.exists()) {
        await meetingsDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}