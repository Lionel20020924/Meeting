import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/openai_service.dart';
import '../../services/transcription_service.dart';
import '../../services/storage_service.dart';

class SummaryController extends GetxController {
  late Map<String, dynamic> meetingData;
  
  final isLoading = false.obs;  // Start with false, only show loading when needed
  final isTranscribing = false.obs;
  final isGeneratingSummary = false.obs;
  final transcript = ''.obs;
  final keyPoints = <String>[].obs;
  final actionItems = <String>[].obs;
  final summary = ''.obs;
  
  // Prompt customization
  final customPrompt = ''.obs;
  final isUsingCustomPrompt = false.obs;
  final promptController = TextEditingController();
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  final isPlaying = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  
  // UI state
  final isTranscriptExpanded = false.obs;  // Start collapsed to show summary first
  
  // Stream subscriptions
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  
  @override
  void onInit() {
    super.onInit();
    // Get the meeting data passed from the recording page
    meetingData = Get.arguments ?? {};
    
    // Check if we should auto-generate summary
    final autoGenerate = meetingData['autoGenerateSummary'] ?? false;
    
    _processTranscription().then((_) {
      // If autoGenerate is true and we have transcription but no summary, generate it
      if (autoGenerate && transcript.value.isNotEmpty && summary.value.isEmpty) {
        // Show loading for summary generation
        isLoading.value = true;
        _generateSummary().then((_) {
          isLoading.value = false;
        });
      }
    });
    
    // Auto-save the meeting data in background
    _autoSaveMeeting();
    // Initialize audio player listeners
    _initAudioPlayer();
  }
  
  @override
  void onClose() {
    // Cancel stream subscriptions first
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    
    // Stop and dispose audio player
    _audioPlayer.stop();
    _audioPlayer.dispose();
    
    // Dispose text controller
    promptController.dispose();
    super.onClose();
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
  
  Future<void> _processTranscription() async {
    try {
      // Step 1: Check if we already have transcription AND summary
      if (meetingData['transcription'] != null && meetingData['transcription'].toString().isNotEmpty) {
        // Use existing transcription
        transcript.value = meetingData['transcription'].toString();
        
        // Check if we already have summary data
        if (meetingData['summary'] != null && meetingData['summary'].toString().isNotEmpty) {
          // Load existing summary data WITHOUT showing loading
          summary.value = meetingData['summary'].toString();
          if (meetingData['keyPoints'] != null) {
            keyPoints.value = List<String>.from(meetingData['keyPoints'] ?? []);
          }
          if (meetingData['actionItems'] != null) {
            actionItems.value = List<String>.from(meetingData['actionItems'] ?? []);
          }
          if (Get.isLogEnable) {
            Get.log('Using existing transcription and summary data');
          }
          // Don't show loading since we have all the data
          isLoading.value = false;
          return;
        }
      }
      
      // Only show loading if we need to process something
      isLoading.value = true;
      
      // Check if we have audio path
      final audioPath = meetingData['audioPath']?.toString();
      if (audioPath == null || audioPath.isEmpty) {
        // If no audio, show basic meeting info without transcription
        _showBasicTranscriptionInfo();
        return;
      }
      
      // No existing transcription, need to transcribe
      try {
        if (Get.isLogEnable) {
          Get.log('No existing transcription, attempting to transcribe audio file: $audioPath');
        }
        await _transcribeAudio(audioPath);
      } catch (e) {
        if (Get.isLogEnable) {
          Get.log('Transcription failed: $e');
        }
        // Show error message
        _showBasicTranscriptionInfo();
      }
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error processing transcription: $e');
      }
      // Show basic meeting info as fallback
      _showBasicTranscriptionInfo();
    } finally {
      isLoading.value = false;
    }
  }
  
  void _showBasicTranscriptionInfo() {
    // Show basic meeting information when transcription fails
    transcript.value = 'Audio transcription not available';
    // Don't generate summary automatically
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
      
      // Check if transcription service is available
      if (!await TranscriptionService.isAvailable()) {
        throw Exception('火山引擎转录服务未配置，请检查 API 密钥设置');
      }
      
      if (Get.isLogEnable) {
        Get.log('Starting transcription with available service...');
      }
      
      // Transcribe using Volcano Engine
      final transcription = await TranscriptionService.transcribeAudioSimple(
        audioData: audioData,
        language: 'zh',
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
      
      // Generate summary using GPT with custom or default prompt
      String prompt;
      
      if (isUsingCustomPrompt.value && customPrompt.value.isNotEmpty) {
        // Use custom prompt with transcript
        prompt = '''${customPrompt.value}

Transcript:
${transcript.value}''';
      } else {
        // Use default prompt
        prompt = '''
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
      }
      
      final response = await OpenAIService.generateChatCompletion(
        prompt: prompt,
        model: 'gpt-3.5-turbo',
        maxTokens: 1000,
      );
      
      // Parse the response
      if (isUsingCustomPrompt.value && customPrompt.value.isNotEmpty) {
        // For custom prompts, just use the raw response as summary
        summary.value = response;
        keyPoints.clear();
        actionItems.clear();
      } else {
        // Parse structured JSON response for default prompt
        _parseGPTResponse(response);
      }
      
      // Save immediately after generating summary
      await _updateSavedMeeting();
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('GPT summary generation failed: $e');
      }
      // If GPT fails, generate basic summary
      _generateBasicSummary();
      // Save the basic summary too
      await _updateSavedMeeting();
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
      // Only show loading for regeneration
      isGeneratingSummary.value = true;
      _generateSummary().then((_) {
        isGeneratingSummary.value = false;
      });
    }
  }
  
  
  // Audio player methods
  void _initAudioPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (!isClosed) {
        isPlaying.value = state == PlayerState.playing;
      }
    });
    
    _positionSubscription = _audioPlayer.onPositionChanged.listen((Duration position) {
      if (!isClosed) {
        currentPosition.value = position;
      }
    });
    
    _durationSubscription = _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (!isClosed) {
        totalDuration.value = duration;
      }
    });
  }
  
  Future<void> togglePlayPause() async {
    try {
      if (isPlaying.value) {
        await _audioPlayer.pause();
      } else {
        final audioPath = meetingData['audioPath']?.toString();
        if (audioPath == null || audioPath.isEmpty) {
          Get.snackbar(
            'Error',
            'Audio file not found',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        
        // Check if audio is already set
        if (_audioPlayer.state == PlayerState.paused) {
          await _audioPlayer.resume();
        } else {
          await _audioPlayer.play(DeviceFileSource(audioPath));
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to play audio: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    currentPosition.value = Duration.zero;
  }
  
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
  
  // Prompt customization methods
  void toggleCustomPrompt() {
    isUsingCustomPrompt.value = !isUsingCustomPrompt.value;
    if (isUsingCustomPrompt.value && customPrompt.value.isEmpty) {
      // Set default custom prompt
      customPrompt.value = 'Please analyze the following meeting transcript and provide a detailed summary with key insights:';
      promptController.text = customPrompt.value;
    }
  }
  
  void updateCustomPrompt(String prompt) {
    customPrompt.value = prompt;
  }
  
  void saveCustomPrompt() {
    customPrompt.value = promptController.text;
    Get.snackbar(
      'Prompt Saved',
      'Custom prompt has been saved',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
  
  void resetToDefaultPrompt() {
    isUsingCustomPrompt.value = false;
    customPrompt.value = '';
    promptController.clear();
  }
  
  // Summary sections management
  bool get hasSummaryContent => 
      summary.value.isNotEmpty || keyPoints.isNotEmpty || actionItems.isNotEmpty;
  
  String get summaryStats {
    final parts = <String>[];
    if (summary.value.isNotEmpty) parts.add('Summary');
    if (keyPoints.isNotEmpty) parts.add('${keyPoints.length} Key Points');
    if (actionItems.isNotEmpty) parts.add('${actionItems.length} Action Items');
    return parts.join(' • ');
  }
  
  void clearAllSummaryData() {
    summary.value = '';
    keyPoints.clear();
    actionItems.clear();
  }
  
  void addKeyPoint(String point) {
    if (point.trim().isNotEmpty && !keyPoints.contains(point.trim())) {
      keyPoints.add(point.trim());
      _updateSavedMeeting();
    }
  }
  
  void removeKeyPoint(int index) {
    if (index >= 0 && index < keyPoints.length) {
      keyPoints.removeAt(index);
      _updateSavedMeeting();
    }
  }
  
  void addActionItem(String item) {
    if (item.trim().isNotEmpty && !actionItems.contains(item.trim())) {
      actionItems.add(item.trim());
      _updateSavedMeeting();
    }
  }
  
  void removeActionItem(int index) {
    if (index >= 0 && index < actionItems.length) {
      actionItems.removeAt(index);
      _updateSavedMeeting();
    }
  }
  
  void toggleActionItemCompletion(int index) {
    // This could be extended to track completion status
    // For now, just show visual feedback
    Get.snackbar(
      'Action Item',
      'Mark as completed functionality can be added here',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
  
  // UI methods
  void toggleTranscriptExpansion() {
    isTranscriptExpanded.value = !isTranscriptExpanded.value;
  }
}