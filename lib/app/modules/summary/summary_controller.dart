import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/openai_service.dart';
import '../../services/storage_service.dart';
import '../meetings/meetings_controller.dart';

class SummaryController extends GetxController {
  late Map<String, dynamic> meetingData;
  
  final isLoading = true.obs;
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
  }
  
  Future<void> _processRecording() async {
    try {
      isLoading.value = true;
      
      // Check if we have audio path
      final audioPath = meetingData['audioPath']?.toString();
      if (audioPath == null || audioPath.isEmpty) {
        Get.snackbar(
          'Error',
          'No audio file found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      // Step 1: Transcribe audio if not already transcribed
      if (meetingData['transcription'] == null || meetingData['transcription'].toString().isEmpty) {
        await _transcribeAudio(audioPath);
      } else {
        transcript.value = meetingData['transcription'].toString();
      }
      
      // Step 2: Generate summary from transcript
      if (transcript.value.isNotEmpty) {
        await _generateSummary();
      }
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _transcribeAudio(String audioPath) async {
    try {
      // Read audio file
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found');
      }
      
      final audioData = await audioFile.readAsBytes();
      
      // Transcribe using OpenAI Whisper
      final transcription = await OpenAIService.transcribeAudio(
        audioData: audioData,
        language: 'en',
      );
      
      transcript.value = transcription;
      
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }
  
  Future<void> _generateSummary() async {
    try {
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
      // If GPT fails, generate basic summary
      _generateBasicSummary();
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
  
  void shareSummary() {
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
    
    // TODO: Implement actual share functionality
    Get.snackbar(
      'Share',
      'Summary copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  Future<void> saveSummary() async {
    try {
      // Update meeting data with transcript and summary
      meetingData['transcription'] = transcript.value;
      meetingData['summary'] = summary.value;
      meetingData['keyPoints'] = keyPoints.toList();
      meetingData['actionItems'] = actionItems.toList();
      
      // Save to storage
      await StorageService.updateMeeting(meetingData);
      
      Get.snackbar(
        'Saved',
        'Meeting summary saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Navigate back to meetings and refresh the list
      Get.until((route) => route.settings.name == '/meetings');
      
      // Refresh meetings list if controller is available
      try {
        final meetingsController = Get.find<MeetingsController>();
        meetingsController.refreshMeetings();
      } catch (e) {
        // Controller not found, navigation will handle refresh
      }
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save summary: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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