import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../../routes/app_pages.dart';
import '../../services/openai_service.dart';

class RecordController extends GetxController {
  final titleController = TextEditingController();
  
  final isRecording = false.obs;
  final isPaused = false.obs;
  final recordingTime = '00:00'.obs;
  final notes = <Map<String, String>>[].obs;
  final isTranscribing = false.obs;
  final transcriptionText = ''.obs;
  
  Timer? _timer;
  int _seconds = 0;
  bool _animationToggle = false;
  
  // Audio recording components
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;
  StreamSubscription<RecordState>? _recordStateSubscription;
  Timer? _transcriptionTimer;
  
  @override
  void onInit() {
    super.onInit();
    _initializeRecorder();
    _listenToRecordingState();
  }

  @override
  void onClose() {
    titleController.dispose();
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _recorder.dispose();
    _recordStateSubscription?.cancel();
    super.onClose();
  }
  
  Future<void> _initializeRecorder() async {
    // Record package doesn't require explicit initialization
    // Just check for permissions when starting recording
  }
  
  void _listenToRecordingState() {
    _recordStateSubscription = _recorder.onStateChanged().listen((RecordState state) {
      if (Get.isLogEnable) {
        Get.log('Recording state changed: $state');
      }
      
      // Update UI based on state if needed
      switch (state) {
        case RecordState.record:
          isRecording.value = true;
          isPaused.value = false;
          break;
        case RecordState.pause:
          isPaused.value = true;
          break;
        case RecordState.stop:
          isRecording.value = false;
          isPaused.value = false;
          break;
      }
    });
  }

  void toggleRecording() {
    if (isRecording.value) {
      // Show dialog to save recording
      _showSaveDialog();
    } else {
      startRecording();
    }
  }

  Future<void> startRecording() async {
    try {
      // Check and request microphone permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        Get.snackbar(
          'Permission Required',
          'Microphone permission is required for recording',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // Start recording
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );
      
      isRecording.value = true;
      _startTimer();
      
      // Periodically transcribe audio chunks
      _startPeriodicTranscription();
      
    } catch (e) {
      Get.snackbar(
        'Recording Error',
        'Failed to start recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void _startPeriodicTranscription() {
    // Transcribe every 10 seconds for more real-time results
    _transcriptionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!isRecording.value || isPaused.value) {
        timer.cancel();
        return;
      }
      _transcribeCurrentRecording();
    });
  }
  
  Future<void> _transcribeCurrentRecording() async {
    if (_recordingPath == null || !isRecording.value) return;
    
    try {
      // Don't start new transcription if one is already in progress
      if (isTranscribing.value) return;
      
      isTranscribing.value = true;
      
      // Stop recording temporarily to read the file
      final currentPath = await _recorder.stop();
      
      if (currentPath != null) {
        // Read the current recording file
        final file = File(currentPath);
        if (await file.exists()) {
          final audioData = await file.readAsBytes();
          
          // Transcribe using OpenAI Whisper
          final transcription = await OpenAIService.transcribeAudio(
            audioData: audioData,
            language: 'en',
          );
          
          if (transcription.isNotEmpty) {
            // Append new transcription to existing text
            if (transcriptionText.value.isNotEmpty) {
              transcriptionText.value += ' ';
            }
            transcriptionText.value += transcription;
          }
        }
        
        // Resume recording with a new file
        _recordingPath = '${(await getTemporaryDirectory()).path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _recorder.start(
          RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _recordingPath!,
        );
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error transcribing audio: $e');
      }
      Get.snackbar(
        'Transcription Error',
        'Failed to transcribe audio. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isTranscribing.value = false;
    }
  }

  void _showSaveDialog() {
    // Pause recording while showing dialog
    if (!isPaused.value) {
      togglePause();
    }
    
    Get.dialog(
      AlertDialog(
        title: const Text('Save Recording'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recording Duration: ${recordingTime.value}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Meeting Title',
                hintText: 'Enter a title for this meeting',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveRecording(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Resume recording
              togglePause();
            },
            child: const Text('Continue Recording'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _discardRecording();
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: _saveRecording,
            child: const Text('Save'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _saveRecording() async {
    if (titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a meeting title',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Stop recording
    await _stopRecording();
    
    // Final transcription
    await _transcribeCurrentRecording();
    
    Get.back(); // Close dialog
    
    // Navigate to summary page after recording
    Get.toNamed(Routes.SUMMARY, arguments: {
      'recordingId': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': titleController.text,
      'duration': recordingTime.value,
      'notes': notes.toList(),
      'transcription': transcriptionText.value,
      'audioPath': _recordingPath,
    });
    
    // Reset state
    _resetRecording();
  }
  
  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      _transcriptionTimer?.cancel();
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error stopping recorder: $e');
      }
    }
  }

  Future<void> _discardRecording() async {
    await _stopRecording();
    
    // Delete recording file if exists
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    _resetRecording();
  }

  void _resetRecording() {
    isRecording.value = false;
    isPaused.value = false;
    isTranscribing.value = false;
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _seconds = 0;
    recordingTime.value = '00:00';
    titleController.clear();
    notes.clear();
    transcriptionText.value = '';
    _recordingPath = null;
  }

  void exitRecording() {
    if (isRecording.value) {
      Get.dialog(
        AlertDialog(
          title: const Text('Exit Recording'),
          content: Text(
            'You have an active recording.\n\nDuration: ${recordingTime.value}\nNotes: ${notes.length}\n\nWhat would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Continue Recording'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _showSaveDialog();
              },
              child: const Text('Save & Exit'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _discardRecording();
                Get.back(); // Go back to home
              },
              child: const Text(
                'Discard & Exit',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }

  void togglePause() async {
    isPaused.value = !isPaused.value;
    if (isPaused.value) {
      _timer?.cancel();
      await _recorder.pause();
    } else {
      _startTimer();
      await _recorder.resume();
    }
  }

  void addNote() {
    final noteController = TextEditingController();
    
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Add Note at ${recordingTime.value}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your note here...',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveNote(noteController.text),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _saveNote(noteController.text),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );
  }

  void _saveNote(String noteText) {
    if (noteText.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a note',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    notes.add({
      'time': recordingTime.value,
      'note': noteText.trim(),
    });
    
    Get.back();
    Get.snackbar(
      'Note Added',
      'Note saved at ${recordingTime.value}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused.value) {
        _seconds++;
        final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (_seconds % 60).toString().padLeft(2, '0');
        recordingTime.value = '$minutes:$seconds';
      }
    });
  }

  void toggleAnimation() {
    _animationToggle = !_animationToggle;
  }
}