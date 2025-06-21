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
      // Load meetings
      List<Map<String, dynamic>> meetings = await loadMeetings();
      
      // Find and remove the meeting
      final meetingIndex = meetings.indexWhere((m) => m['id'] == meetingId);
      if (meetingIndex != -1) {
        final meeting = meetings[meetingIndex];
        
        // Delete audio file if exists
        if (meeting['audioPath'] != null) {
          final audioFile = File(meeting['audioPath']);
          if (await audioFile.exists()) {
            await audioFile.delete();
          }
        }
        
        // Remove from list and save
        meetings.removeAt(meetingIndex);
        
        final meetingsDir = await _meetingsDirectory;
        final file = File('${meetingsDir.path}/$_meetingsFile');
        await file.writeAsString(jsonEncode(meetings));
      }
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