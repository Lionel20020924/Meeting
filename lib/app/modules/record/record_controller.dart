import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';
import '../../services/openai_service.dart';

class RecordController extends GetxController {
  final titleController = TextEditingController();
  
  final isRecording = false.obs;
  final isPaused = false.obs;
  final recordingTime = '00:00'.obs;
  final notes = <Map<String, String>>[].obs;
  final transcribedText = ''.obs; // Real-time transcription text
  final isTranscribing = false.obs;
  
  Timer? _timer;
  Timer? _transcriptionTimer;
  int _seconds = 0;
  bool _animationToggle = false;
  
  // Audio recording components
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;
  StreamSubscription<RecordState>? _recordStateSubscription;
  
  // Transcription chunks for real-time processing
  List<String> _audioChunks = [];
  
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
    _cleanupChunks();
    super.onClose();
  }
  
  void _cleanupChunks() async {
    // Clean up temporary chunk files
    for (final chunkPath in _audioChunks) {
      try {
        final file = File(chunkPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    _audioChunks.clear();
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

  void toggleRecording() async {
    if (isRecording.value) {
      // Stop recording first, then show save dialog
      await _stopRecording();
      _showSaveDialog();
    } else {
      await startRecording();
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
          bitRate: 192000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );
      
      isRecording.value = true;
      _startTimer();
      _startRealtimeTranscription();
      
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
  

  void _showSaveDialog() {
    // Recording is already stopped at this point
    
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
    
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      
      // Recording already stopped, just save the file
      
      // Save audio file to permanent storage
      String permanentAudioPath = '';
      if (_recordingPath != null) {
        permanentAudioPath = await StorageService.saveAudioFile(_recordingPath!);
      }
      
      // Create meeting data
      final meetingData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': titleController.text,
        'date': DateTime.now().toIso8601String(),
        'duration': recordingTime.value,
        'notes': notes.map((note) => Map<String, dynamic>.from(note)).toList(),
        'audioPath': permanentAudioPath,
        'participants': '1',
        'transcription': transcribedText.value, // Include real-time transcription
      };
      
      // Close loading dialog
      Get.back();
      // Close save dialog
      Get.back();
      
      // Navigate to post-recording options page
      Get.toNamed(Routes.POST_RECORDING, arguments: meetingData);
      
      // Reset state
      _resetRecording();
      
    } catch (e) {
      Get.back(); // Close loading dialog if open
      Get.snackbar(
        'Error',
        'Failed to save recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> _stopRecording() async {
    try {
      // Stop real-time transcription
      _stopRealtimeTranscription();
      
      // Stop the recorder and get the final path
      final finalPath = await _recorder.stop();
      if (finalPath != null) {
        _recordingPath = finalPath;
      }
      isRecording.value = false;
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
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _seconds = 0;
    recordingTime.value = '00:00';
    titleController.clear();
    notes.clear();
    transcribedText.value = '';
    _recordingPath = null;
    _cleanupChunks();
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
  
  void _startRealtimeTranscription() {
    // For real-time transcription, we'll process the audio periodically
    // Note: This is a simplified implementation. For true real-time transcription,
    // you would need to implement streaming audio to the API
    
    _transcriptionTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!isRecording.value || isPaused.value) return;
      
      // Transcribe accumulated audio
      await _transcribeAccumulatedAudio();
    });
  }
  
  Future<void> _transcribeAccumulatedAudio() async {
    try {
      if (_recordingPath == null) return;
      
      // Check if file exists and has content
      final audioFile = File(_recordingPath!);
      if (!await audioFile.exists()) return;
      
      final fileSize = await audioFile.length();
      if (fileSize < 1000) return; // Skip if file too small
      
      isTranscribing.value = true;
      
      // Read current recording
      final audioData = await audioFile.readAsBytes();
      
      // Transcribe using OpenAI Whisper (Chinese)
      final transcription = await OpenAIService.transcribeAudio(
        audioData: audioData,
        language: 'zh',
      );
      
      // Update transcription (replace with new full transcription)
      if (transcription.isNotEmpty) {
        transcribedText.value = transcription;
      }
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error transcribing audio: $e');
      }
    } finally {
      isTranscribing.value = false;
    }
  }
  
  void _stopRealtimeTranscription() {
    _transcriptionTimer?.cancel();
    _transcriptionTimer = null;
  }
}