import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';
import '../../services/transcription_service.dart';

class RecordController extends GetxController with GetSingleTickerProviderStateMixin {
  final titleController = TextEditingController();
  
  final isRecording = false.obs;
  final isPaused = false.obs;
  final recordingTime = '00:00'.obs;
  final notes = <Map<String, String>>[].obs;
  final transcribedText = ''.obs; // Real-time transcription text
  final isTranscribing = false.obs;
  final recordingStartTime = Rxn<DateTime>();
  final elapsedTime = ''.obs;
  
  Timer? _timer;
  Timer? _transcriptionTimer;
  int _seconds = 0;
  bool _animationToggle = false;
  
  // Animation controller for pulse effect
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;
  
  // Audio level monitoring
  final audioLevel = 0.0.obs; // Current audio level (0.0 to 1.0)
  final waveformData = <double>[].obs; // Historical waveform data points
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _waveformTimer;
  static const int maxWaveformPoints = 60; // Number of points to display
  
  // Smoothing variables
  final List<double> _recentLevels = [];
  static const int _smoothingWindow = 3;
  
  // Audio recording components
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;
  StreamSubscription<RecordState>? _recordStateSubscription;
  
  // Transcription chunks for real-time processing
  final List<String> _audioChunks = [];
  
  @override
  void onInit() {
    super.onInit();
    _initializeRecorder();
    _listenToRecordingState();
    
    // Initialize pulse animation
    pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: pulseController,
      curve: Curves.easeInOut,
    ));
    pulseController.repeat(reverse: true);
    
    // Initialize waveform data with zeros
    waveformData.value = List.filled(maxWaveformPoints, 0.0);
  }

  @override
  void onClose() {
    titleController.dispose();
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _waveformTimer?.cancel();
    pulseController.dispose();
    _recorder.dispose();
    _recordStateSubscription?.cancel();
    _amplitudeSubscription?.cancel();
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
      _startAudioLevelMonitoring();
      
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
    // Generate automatic title based on current time and duration
    _generateAutoTitle();
    
    Get.dialog(
      AlertDialog(
        title: const Text('保存录音'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '录音时长: ${recordingTime.value}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '会议标题',
                hintText: '可以修改自动生成的标题',
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
              '丢弃',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: _saveRecording,
            child: const Text('保存'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _saveRecording() async {
    if (titleController.text.isEmpty) {
      Get.snackbar(
        '错误',
        '请输入会议标题',
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
      _stopAudioLevelMonitoring();
      
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
    recordingStartTime.value = null;
    elapsedTime.value = '';
    _cleanupChunks();
    _recentLevels.clear();
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
    recordingStartTime.value = DateTime.now();
    _updateElapsedTime();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused.value) {
        _seconds++;
        final hours = _seconds ~/ 3600;
        final minutes = (_seconds % 3600) ~/ 60;
        final seconds = _seconds % 60;
        
        if (hours > 0) {
          recordingTime.value = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else {
          recordingTime.value = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }
        
        _updateElapsedTime();
      }
    });
  }
  
  void _updateElapsedTime() {
    if (recordingStartTime.value != null) {
      final now = DateTime.now();
      final difference = now.difference(recordingStartTime.value!);
      
      if (difference.inMinutes < 1) {
        elapsedTime.value = 'Just started';
      } else if (difference.inHours < 1) {
        final mins = difference.inMinutes;
        elapsedTime.value = '$mins minute${mins > 1 ? 's' : ''} ago';
      } else {
        final hours = difference.inHours;
        elapsedTime.value = '$hours hour${hours > 1 ? 's' : ''} ago';
      }
    }
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
      
      // Transcribe using available transcription service (WhisperX preferred, fallback to OpenAI)
      final transcription = await TranscriptionService.transcribeAudioSimple(
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
  
  void _generateAutoTitle() {
    final now = DateTime.now();
    final dateStr = '${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final duration = recordingTime.value;
    
    // Generate title based on time and duration
    titleController.text = '$dateStr $timeStr 会议 ($duration)';
  }
  
  // Audio level monitoring methods
  void _startAudioLevelMonitoring() {
    // Listen to amplitude stream from recorder with higher frequency for smoother animation
    _amplitudeSubscription = _recorder.onAmplitudeChanged(const Duration(milliseconds: 50)).listen((amplitude) {
      // Calculate normalized audio level (0.0 to 1.0)
      // Amplitude.current ranges from -160 to 0 dB
      final normalizedLevel = _normalizeAudioLevel(amplitude.current);
      audioLevel.value = normalizedLevel;
      
      // Update waveform data
      _updateWaveformData(normalizedLevel);
    });
    
    // Also update waveform periodically to ensure smooth animation
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isRecording.value || isPaused.value) {
        // Add zero values when paused to show silence with smooth decay
        final lastValue = waveformData.isNotEmpty ? waveformData.last : 0.0;
        _updateWaveformData(lastValue * 0.85); // Smooth decay
      }
    });
  }
  
  void _stopAudioLevelMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _waveformTimer?.cancel();
    _waveformTimer = null;
    audioLevel.value = 0.0;
    
    // Clear waveform data
    waveformData.value = List.filled(maxWaveformPoints, 0.0);
  }
  
  double _normalizeAudioLevel(double dbLevel) {
    // Convert dB level to normalized value (0.0 to 1.0)
    // -160 dB = silence (0.0), 0 dB = maximum (1.0)
    // Use -45 dB as practical minimum for better sensitivity
    const double minDb = -45.0;
    const double maxDb = -5.0; // Use -5 dB as practical maximum for better range
    
    if (dbLevel <= minDb) return 0.0;
    if (dbLevel >= maxDb) return 1.0;
    
    // Linear interpolation between min and max
    final normalized = (dbLevel - minDb) / (maxDb - minDb);
    
    // Apply smoothing curve for better visualization with less aggressive curve
    return math.pow(normalized, 1.2).toDouble();
  }
  
  void _updateWaveformData(double level) {
    // Add to recent levels for smoothing
    _recentLevels.add(level);
    if (_recentLevels.length > _smoothingWindow) {
      _recentLevels.removeAt(0);
    }
    
    // Calculate smoothed level
    double smoothedLevel = level;
    if (_recentLevels.length >= 2) {
      // Apply exponential moving average
      double sum = 0;
      double weight = 1;
      double totalWeight = 0;
      
      for (int i = _recentLevels.length - 1; i >= 0; i--) {
        sum += _recentLevels[i] * weight;
        totalWeight += weight;
        weight *= 0.7; // Decay factor
      }
      
      smoothedLevel = sum / totalWeight;
    }
    
    final List<double> newData = List.from(waveformData);
    
    // Shift existing data to the left
    for (int i = 0; i < newData.length - 1; i++) {
      newData[i] = newData[i + 1];
    }
    
    // Add smoothed level at the end
    newData[newData.length - 1] = smoothedLevel;
    
    // Apply additional smoothing to the entire waveform
    for (int i = 1; i < newData.length - 1; i++) {
      final prev = newData[i - 1];
      final curr = newData[i];
      final next = newData[i + 1];
      newData[i] = curr * 0.5 + prev * 0.25 + next * 0.25;
    }
    
    waveformData.value = newData;
  }
}