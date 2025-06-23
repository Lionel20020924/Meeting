import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';

class PostRecordingController extends GetxController {
  late Map<String, dynamic> meetingData;
  final RxBool isGeneratingSummary = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isEditingTitle = false.obs;
  final TextEditingController titleController = TextEditingController();
  
  // Audio player for preview
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RxBool isPlayingPreview = false.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    meetingData = Get.arguments ?? {};
    titleController.text = meetingData['title'] ?? 'Untitled Meeting';
  }
  
  @override
  void onClose() {
    titleController.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> saveWithoutSummary() async {
    try {
      isSaving.value = true;
      
      // Save meeting data to storage
      await StorageService.saveMeeting(meetingData);
      
      // Navigate back to home page
      Get.offAllNamed(Routes.HOME);
      
      Get.snackbar(
        'Success',
        'Meeting saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save meeting: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> generateSummaryAndSave() async {
    try {
      isGeneratingSummary.value = true;
      
      // Save meeting data first
      await StorageService.saveMeeting(meetingData);
      
      // Navigate directly to summary page - it will handle transcription and summary
      Get.offNamedUntil(
        Routes.SUMMARY,
        (route) => route.settings.name == Routes.HOME,
        arguments: meetingData,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process meeting: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isGeneratingSummary.value = false;
    }
  }

  void viewMeetingDetails() {
    // Preview the meeting details
    final title = meetingData['title'] ?? 'Untitled';
    final duration = meetingData['duration'] ?? '00:00';
    final notesCount = (meetingData['notes'] as List?)?.length ?? 0;
    final hasTranscription = meetingData['transcription']?.toString().isNotEmpty ?? false;

    Get.dialog(
      AlertDialog(
        title: const Text('Meeting Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Title', title),
            _buildDetailRow('Duration', duration),
            _buildDetailRow('Notes', '$notesCount notes'),
            _buildDetailRow('Transcription', hasTranscription ? 'Available' : 'Not available'),
            if (meetingData['audioPath'] != null)
              _buildDetailRow('Audio', 'Recording saved'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  void startEditingTitle() {
    isEditingTitle.value = true;
    titleController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: titleController.text.length,
    );
  }
  
  void saveTitle() {
    if (titleController.text.trim().isNotEmpty) {
      meetingData['title'] = titleController.text.trim();
      isEditingTitle.value = false;
    } else {
      titleController.text = meetingData['title'] ?? 'Untitled Meeting';
      isEditingTitle.value = false;
    }
  }
  
  String getFileSize() {
    // Mock file size calculation
    // In a real app, this would calculate actual file size
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final sizeInMB = 5 + (random / 10);
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }
  
  void playPreview() {
    final audioPath = meetingData['audioPath']?.toString();
    
    if (audioPath == null || audioPath.isEmpty) {
      Get.snackbar(
        'Error',
        'No audio file found for preview',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Check if audio file exists
    final audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      Get.snackbar(
        'Error',
        'Audio file not found at specified path',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    _initializeAudioPlayer();
    _showAudioPreviewDialog();
  }
  
  void _initializeAudioPlayer() {
    // Set up audio player listeners
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      isPlayingPreview.value = state == PlayerState.playing;
    });
    
    _audioPlayer.onPositionChanged.listen((Duration position) {
      currentPosition.value = position;
    });
    
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      totalDuration.value = duration;
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      isPlayingPreview.value = false;
      currentPosition.value = Duration.zero;
    });
  }
  
  void _showAudioPreviewDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.headphones, color: Colors.blue),
            SizedBox(width: 8),
            Text('Audio Preview'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Meeting info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meetingData['title'] ?? 'Untitled Meeting',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${meetingData['duration'] ?? '00:00'}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Audio controls
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip backward button
                  IconButton(
                    onPressed: () => _skipBackward(),
                    icon: const Icon(Icons.replay_10),
                    tooltip: 'Rewind 10s',
                  ),
                  
                  // Play/Pause button
                  GestureDetector(
                    onTap: () => _togglePlayPause(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        isPlayingPreview.value ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  
                  // Skip forward button
                  IconButton(
                    onPressed: () => _skipForward(),
                    icon: const Icon(Icons.forward_10),
                    tooltip: 'Forward 10s',
                  ),
                ],
              )),
              
              const SizedBox(height: 16),
              
              // Progress bar and time
              Obx(() {
                final position = currentPosition.value;
                final duration = totalDuration.value;
                final progress = duration.inMilliseconds > 0 
                    ? position.inMilliseconds / duration.inMilliseconds 
                    : 0.0;
                
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(Get.context!).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final newPosition = Duration(
                            milliseconds: (value * duration.inMilliseconds).round(),
                          );
                          _seekTo(newPosition);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _stopAudio();
              Get.back();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _togglePlayPause() async {
    try {
      final audioPath = meetingData['audioPath']?.toString();
      if (audioPath == null) return;
      
      if (isPlayingPreview.value) {
        await _audioPlayer.pause();
      } else {
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
  
  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    isPlayingPreview.value = false;
    currentPosition.value = Duration.zero;
  }
  
  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  Future<void> _skipForward() async {
    final newPosition = currentPosition.value + const Duration(seconds: 10);
    if (newPosition <= totalDuration.value) {
      await _seekTo(newPosition);
    }
  }
  
  Future<void> _skipBackward() async {
    final newPosition = currentPosition.value - const Duration(seconds: 10);
    await _seekTo(newPosition.isNegative ? Duration.zero : newPosition);
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
  
  void shareRecording() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Recording',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Share',
                  'Sharing via email...',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Message'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Share',
                  'Sharing via message...',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Cloud Storage'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Share',
                  'Uploading to cloud...',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void addTags() {
    final tags = meetingData['tags'] as List<String>? ?? [];
    final tagController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Add Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tagController,
              decoration: const InputDecoration(
                hintText: 'Enter tag name',
                prefixIcon: Icon(Icons.label),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  tags.add(value.trim());
                  meetingData['tags'] = tags;
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Tag added successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            if (tags.isNotEmpty) ...[
              const Text(
                'Existing tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: tags.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    tags.remove(tag);
                    meetingData['tags'] = tags;
                    Get.back();
                    addTags(); // Reopen dialog
                  },
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tagController.text.trim().isNotEmpty) {
                tags.add(tagController.text.trim());
                meetingData['tags'] = tags;
                Get.back();
                Get.snackbar(
                  'Success',
                  'Tag added successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Add Tag'),
          ),
        ],
      ),
    );
  }
  
  Future<void> discardRecording() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Discard Recording?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to discard this recording?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone. The recording will be permanently deleted.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Delete the audio file if it exists
      if (meetingData['audioPath'] != null) {
        try {
          // In a real app, delete the file here
          // File(meetingData['audioPath']).deleteSync();
        } catch (e) {
          // Handle error
        }
      }
      
      // Navigate back to home
      Get.offAllNamed(Routes.HOME);
      
      Get.snackbar(
        'Recording Discarded',
        'The recording has been deleted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }
}