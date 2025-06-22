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

  @override
  void onInit() {
    super.onInit();
    meetingData = Get.arguments ?? {};
    titleController.text = meetingData['title'] ?? 'Untitled Meeting';
  }
  
  @override
  void onClose() {
    titleController.dispose();
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
    Get.dialog(
      AlertDialog(
        title: const Text('Preview Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_filled,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Playing: ${meetingData['title'] ?? 'Untitled Meeting'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${meetingData['duration'] ?? '00:00'}',
              style: const TextStyle(color: Colors.grey),
            ),
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