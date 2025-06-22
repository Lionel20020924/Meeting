import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/openai_service.dart';
import '../../services/storage_service.dart';

class SummaryController extends GetxController {
  late Map<String, dynamic> meetingData;
  
  final isLoading = true.obs;
  final isTranscribing = false.obs;
  final isGeneratingSummary = false.obs;
  final transcript = ''.obs;
  final keyPoints = <String>[].obs;
  final actionItems = <String>[].obs;
  final summary = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Get the meeting data passed from the recording page
    meetingData = Get.arguments ?? {};
    _processRecording();
    // Auto-save the meeting data in background
    _autoSaveMeeting();
  }
  
  Future<void> _autoSaveMeeting() async {
    // Wait a bit to ensure meeting data is available
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // Check if meeting is already saved
      final meetings = await StorageService.loadMeetings();
      final isAlreadySaved = meetings.any((m) => m['id'] == meetingData['id']);
      
      if (!isAlreadySaved) {
        // Save the basic meeting data immediately if not already saved
        await StorageService.saveMeeting(meetingData);
      }
      
      // Update with transcript and summary when available
      ever(transcript, (_) => _updateSavedMeeting());
      ever(summary, (_) => _updateSavedMeeting());
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error auto-saving meeting: $e');
      }
    }
  }
  
  Future<void> _updateSavedMeeting() async {
    try {
      // Update meeting data with latest transcript and summary
      meetingData['transcription'] = transcript.value;
      meetingData['summary'] = summary.value;
      meetingData['keyPoints'] = keyPoints.toList();
      meetingData['actionItems'] = actionItems.toList();
      
      // Update in storage
      await StorageService.updateMeeting(meetingData);
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error updating saved meeting: $e');
      }
    }
  }
  
  Future<void> _processRecording() async {
    try {
      isLoading.value = true;
      
      // Step 1: Check if we already have complete summary data
      if (meetingData['summary'] != null && meetingData['summary'].toString().isNotEmpty) {
        // Use existing summary data directly
        transcript.value = meetingData['transcription']?.toString() ?? '';
        summary.value = meetingData['summary'].toString();
        
        // Load existing key points and action items if available
        if (meetingData['keyPoints'] != null) {
          keyPoints.value = List<String>.from(meetingData['keyPoints'] ?? []);
        }
        if (meetingData['actionItems'] != null) {
          actionItems.value = List<String>.from(meetingData['actionItems'] ?? []);
        }
        
        if (Get.isLogEnable) {
          Get.log('Using existing complete summary data');
        }
        return;
      }
      
      // Check if we have audio path
      final audioPath = meetingData['audioPath']?.toString();
      if (audioPath == null || audioPath.isEmpty) {
        // If no audio, show basic meeting info without transcription
        _showBasicMeetingInfo();
        return;
      }
      
      // Step 2: Check if we already have transcription but need summary
      if (meetingData['transcription'] != null && meetingData['transcription'].toString().isNotEmpty) {
        // Use existing transcription
        transcript.value = meetingData['transcription'].toString();
        if (Get.isLogEnable) {
          Get.log('Using existing transcription: ${transcript.value.substring(0, transcript.value.length > 100 ? 100 : transcript.value.length)}...');
        }
        
        // Skip to summary generation
        isTranscribing.value = false;
        await _generateSummary();
      } else {
        // No existing transcription, need to transcribe
        try {
          if (Get.isLogEnable) {
            Get.log('No existing transcription, attempting to transcribe audio file: $audioPath');
          }
          await _transcribeAudio(audioPath);
          
          // After successful transcription, generate summary
          if (transcript.value.isNotEmpty) {
            await _generateSummary();
          } else {
            _showBasicMeetingInfo();
          }
        } catch (e) {
          if (Get.isLogEnable) {
            Get.log('Transcription failed: $e');
          }
          // Continue with basic summary even if transcription fails
          _showBasicMeetingInfo();
        }
      }
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error processing recording: $e');
      }
      // Show basic meeting info as fallback
      _showBasicMeetingInfo();
    } finally {
      isLoading.value = false;
    }
  }
  
  void _showBasicMeetingInfo() {
    // Show basic meeting information when API fails
    final duration = meetingData['duration']?.toString() ?? '00:00';
    final title = meetingData['title']?.toString() ?? 'Meeting';
    
    transcript.value = 'Audio transcription not available';
    summary.value = 'Meeting "$title" was recorded with duration of $duration. '
                   'Audio file has been saved for future processing.';
    
    // Add basic info as key points
    keyPoints.value = [
      'Meeting duration: $duration',
      'Recording date: ${DateTime.now().toString().substring(0, 16)}',
      'Audio file saved successfully',
    ];
    
    actionItems.value = [
      'Review meeting audio file',
      'Follow up on discussed topics',
    ];
  }
  
  Future<void> _transcribeAudio(String audioPath) async {
    try {
      isTranscribing.value = true;
      
      // Read audio file
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found at path: $audioPath');
      }
      
      final fileSize = await audioFile.length();
      if (Get.isLogEnable) {
        Get.log('Audio file size: ${fileSize / 1024} KB');
      }
      
      if (fileSize < 1000) {
        throw Exception('Audio file too small: $fileSize bytes');
      }
      
      final audioData = await audioFile.readAsBytes();
      
      // Check API key
      if (dotenv.env['OPENAI_API_KEY'] == null || dotenv.env['OPENAI_API_KEY']!.isEmpty) {
        throw Exception('OpenAI API key not configured');
      }
      
      if (Get.isLogEnable) {
        Get.log('Starting transcription with Whisper API...');
      }
      
      // Transcribe using OpenAI Whisper
      final transcription = await OpenAIService.transcribeAudio(
        audioData: audioData,
        language: 'en',
      );
      
      if (transcription.isEmpty) {
        throw Exception('Transcription returned empty result');
      }
      
      transcript.value = transcription;
      
      // Update meeting data with transcription
      meetingData['transcription'] = transcription;
      await StorageService.updateMeeting(meetingData);
      
      if (Get.isLogEnable) {
        Get.log('Transcription successful: ${transcription.substring(0, transcription.length > 100 ? 100 : transcription.length)}...');
      }
      
    } catch (e) {
      throw Exception('Transcription failed: $e');
    } finally {
      isTranscribing.value = false;
    }
  }
  
  Future<void> _generateSummary() async {
    try {
      isGeneratingSummary.value = true;
      
      // Check if we have a valid API key
      if (dotenv.env['OPENAI_API_KEY'] == null || dotenv.env['OPENAI_API_KEY']!.isEmpty) {
        if (Get.isLogEnable) {
          Get.log('OpenAI API key not found, using basic summary');
        }
        _generateBasicSummary();
        return;
      }
      
      // Generate summary using GPT
      final prompt = '''
Please analyze the following meeting transcript and provide:

1. A brief summary (2-3 sentences)
2. Key points discussed (bullet points)
3. Action items identified (bullet points)

Format your response as JSON with the following structure:
{
  "summary": "Brief summary here",
  "keyPoints": ["point 1", "point 2", ...],
  "actionItems": ["action 1", "action 2", ...]
}

Transcript:
${transcript.value}
''';
      
      final response = await OpenAIService.generateChatCompletion(
        prompt: prompt,
        model: 'gpt-3.5-turbo',
        maxTokens: 1000,
      );
      
      // Parse the response
      _parseGPTResponse(response);
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('GPT summary generation failed: $e');
      }
      // If GPT fails, generate basic summary
      _generateBasicSummary();
    } finally {
      isGeneratingSummary.value = false;
    }
  }
  
  void _parseGPTResponse(String response) {
    try {
      // Try to extract JSON from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonStr);
        
        summary.value = data['summary'] ?? '';
        
        if (data['keyPoints'] != null) {
          keyPoints.value = List<String>.from(data['keyPoints']);
        }
        
        if (data['actionItems'] != null) {
          actionItems.value = List<String>.from(data['actionItems']);
        }
      } else {
        _generateBasicSummary();
      }
    } catch (e) {
      _generateBasicSummary();
    }
  }
  
  void _generateBasicSummary() {
    // Basic summary generation without GPT
    final words = transcript.value.split(' ');
    final wordCount = words.length;
    final duration = meetingData['duration']?.toString() ?? '00:00';
    
    summary.value = 'Meeting recorded on ${DateTime.now().toString().substring(0, 10)} '
                   'with duration of $duration. '
                   'Transcript contains $wordCount words.';
    
    // Extract potential key points (sentences with important keywords)
    final sentences = transcript.value.split(RegExp(r'[.!?]'));
    final importantKeywords = ['important', 'discuss', 'plan', 'decide', 'agree', 'need', 'will', 'should'];
    
    keyPoints.clear();
    for (final sentence in sentences) {
      final lowerSentence = sentence.toLowerCase();
      if (importantKeywords.any((keyword) => lowerSentence.contains(keyword)) && 
          sentence.trim().length > 20) {
        keyPoints.add(sentence.trim());
        if (keyPoints.length >= 5) break;
      }
    }
    
    // Extract potential action items (sentences with action words)
    final actionKeywords = ['will', 'need to', 'should', 'must', 'have to', 'going to'];
    
    actionItems.clear();
    for (final sentence in sentences) {
      final lowerSentence = sentence.toLowerCase();
      if (actionKeywords.any((keyword) => lowerSentence.contains(keyword)) && 
          sentence.trim().length > 20 &&
          !keyPoints.contains(sentence.trim())) {
        actionItems.add(sentence.trim());
        if (actionItems.length >= 5) break;
      }
    }
  }
  
  void shareSummary() async {
    final shareText = '''
Meeting: ${meetingData['title'] ?? 'Untitled'}
Date: ${DateTime.now().toString().substring(0, 10)}
Duration: ${meetingData['duration'] ?? '00:00'}

Summary:
${summary.value}

Key Points:
${keyPoints.map((point) => '• $point').join('\n')}

Action Items:
${actionItems.map((item) => '☐ $item').join('\n')}

Full Transcript:
${transcript.value}
''';
    
    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      Get.snackbar(
        'Success',
        'Summary copied to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to copy to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void finishAndReturn() {
    // Simply navigate back to home page
    // Meeting is already auto-saved
    Get.offAllNamed(Routes.HOME);
  }
  
  void regenerateSummary() {
    if (transcript.value.isNotEmpty) {
      isLoading.value = true;
      _generateSummary().then((_) {
        isLoading.value = false;
      });
    }
  }
}