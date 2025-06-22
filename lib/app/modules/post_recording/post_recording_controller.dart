import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';

class PostRecordingController extends GetxController {
  late Map<String, dynamic> meetingData;
  final RxBool isGeneratingSummary = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    meetingData = Get.arguments ?? {};
  }

  Future<void> saveWithoutSummary() async {
    try {
      isSaving.value = true;
      
      // Save meeting data to storage
      await StorageService.saveMeeting(meetingData);
      
      // Navigate to meeting detail
      Get.offNamedUntil(
        Routes.MEETING_DETAIL,
        (route) => route.settings.name == Routes.HOME,
        arguments: meetingData,
      );
      
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
      
      // Navigate to summary page to generate summary
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
}