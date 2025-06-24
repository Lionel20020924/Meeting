import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../routes/app_pages.dart';
import '../../services/transcription_service.dart';
import '../../services/storage_service.dart';

class MeetingDetailController extends GetxController {
  late Map<String, dynamic> meeting;
  final AudioPlayer audioPlayer = AudioPlayer();
  
  final RxBool isPlaying = false.obs;
  final RxBool isTranscribing = false.obs;
  final RxString transcription = ''.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  
  // Search functionality
  final RxBool showSearch = false.obs;
  final TextEditingController searchController = TextEditingController();
  final RxString highlightedTranscription = ''.obs;
  
  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  @override
  void onInit() {
    super.onInit();
    meeting = Get.arguments ?? {};
    
    // Initialize transcription if it exists
    if (meeting['transcription'] != null && meeting['transcription'].toString().isNotEmpty) {
      transcription.value = meeting['transcription'];
    }
    
    // Setup audio player listeners
    _positionSubscription = audioPlayer.onPositionChanged.listen((pos) {
      if (!isClosed) {
        position.value = pos;
      }
    });
    
    _durationSubscription = audioPlayer.onDurationChanged.listen((dur) {
      if (!isClosed) {
        duration.value = dur;
      }
    });
    
    _playerCompleteSubscription = audioPlayer.onPlayerComplete.listen((_) {
      if (!isClosed) {
        isPlaying.value = false;
        position.value = Duration.zero;
      }
    });
  }

  @override
  void onClose() {
    // Cancel stream subscriptions first
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    
    // Stop and dispose audio player
    audioPlayer.stop();
    audioPlayer.dispose();
    
    // Dispose text controller
    searchController.dispose();
    super.onClose();
  }

  void viewFullSummary() {
    Get.toNamed(Routes.SUMMARY, arguments: meeting);
  }

  Future<void> togglePlayPause() async {
    try {
      if (meeting['audioPath'] == null || meeting['audioPath'].toString().isEmpty) {
        errorMessage.value = 'No audio file found';
        return;
      }

      if (isPlaying.value) {
        await audioPlayer.pause();
        isPlaying.value = false;
      } else {
        final audioFile = File(meeting['audioPath']);
        if (!audioFile.existsSync()) {
          errorMessage.value = 'Audio file not found';
          return;
        }
        
        await audioPlayer.play(DeviceFileSource(meeting['audioPath']));
        isPlaying.value = true;
      }
    } catch (e) {
      errorMessage.value = 'Error playing audio: $e';
      isPlaying.value = false;
    }
  }

  Future<void> seekTo(double value) async {
    final position = Duration(seconds: value.toInt());
    await audioPlayer.seek(position);
  }

  Future<void> transcribeAudio() async {
    try {
      if (meeting['audioPath'] == null || meeting['audioPath'].toString().isEmpty) {
        errorMessage.value = 'No audio file found';
        return;
      }

      final audioFile = File(meeting['audioPath']);
      if (!audioFile.existsSync()) {
        errorMessage.value = 'Audio file not found';
        return;
      }

      isTranscribing.value = true;
      errorMessage.value = '';

      // Read audio file
      final audioData = await audioFile.readAsBytes();
      
      // Transcribe using available service (WhisperX preferred, fallback to OpenAI)
      final result = await TranscriptionService.transcribeAudioSimple(
        audioData: audioData,
        language: 'zh',
      );

      transcription.value = result;
      
      // Update meeting data with transcription
      meeting['transcription'] = result;
      await StorageService.updateMeeting(meeting);

    } catch (e) {
      errorMessage.value = 'Error transcribing audio: $e';
    } finally {
      isTranscribing.value = false;
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  // Skip audio controls
  Future<void> skipForward() async {
    final newPosition = position.value + const Duration(seconds: 10);
    if (newPosition < duration.value) {
      await audioPlayer.seek(newPosition);
    }
  }
  
  Future<void> skipBackward() async {
    final newPosition = position.value - const Duration(seconds: 10);
    await audioPlayer.seek(newPosition.isNegative ? Duration.zero : newPosition);
  }
  
  // Search functionality
  void toggleSearch() {
    showSearch.value = !showSearch.value;
    if (!showSearch.value) {
      searchController.clear();
      highlightedTranscription.value = '';
    }
  }
  
  void searchInTranscription(String query) {
    if (query.isEmpty) {
      highlightedTranscription.value = '';
      return;
    }
    
    // Simple highlight implementation - in production, use proper text highlighting
    highlightedTranscription.value = transcription.value;
  }
  
  // Copy and share functionality
  void copyTranscription() {
    Clipboard.setData(ClipboardData(text: transcription.value));
    Get.snackbar(
      'Copied',
      'Transcription copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
  
  void shareMeeting() {
    final shareText = '''
Meeting: ${meeting['title'] ?? 'Untitled'}
Date: ${meeting['date'] ?? 'No date'}
Duration: ${meeting['duration'] ?? '00:00'}

${transcription.value.isNotEmpty ? 'Transcription:\n${transcription.value}' : 'No transcription available'}
''';
    
    Clipboard.setData(ClipboardData(text: shareText));
    Get.snackbar(
      'Share',
      'Meeting details copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }
}