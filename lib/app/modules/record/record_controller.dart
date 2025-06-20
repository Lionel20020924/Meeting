import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';

class RecordController extends GetxController {
  final titleController = TextEditingController();
  
  final isRecording = false.obs;
  final isPaused = false.obs;
  final recordingTime = '00:00'.obs;
  
  Timer? _timer;
  int _seconds = 0;
  
  @override
  void onClose() {
    titleController.dispose();
    _timer?.cancel();
    super.onClose();
  }

  void toggleRecording() {
    if (isRecording.value) {
      stopRecording();
    } else {
      startRecording();
    }
  }

  void startRecording() {
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
    
    // TODO: Implement actual recording logic
    isRecording.value = true;
    _startTimer();
  }

  void stopRecording() {
    // TODO: Implement stop recording logic
    isRecording.value = false;
    isPaused.value = false;
    _timer?.cancel();
    
    if (_seconds > 0) {
      // Navigate to summary page after recording
      Get.offNamed(Routes.SUMMARY, arguments: {
        'recordingId': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': titleController.text,
        'duration': recordingTime.value,
      });
    }
  }

  void cancelRecording() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Recording'),
        content: const Text('Are you sure you want to cancel this recording? All data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Continue Recording'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              isRecording.value = false;
              isPaused.value = false;
              _timer?.cancel();
              _seconds = 0;
              recordingTime.value = '00:00';
              Get.back();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void togglePause() {
    isPaused.value = !isPaused.value;
    if (isPaused.value) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  void addNote() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your note here...',
                border: OutlineInputBorder(),
              ),
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
                  onPressed: () {
                    // TODO: Save note with timestamp
                    Get.back();
                    Get.snackbar(
                      'Note Added',
                      'Note saved at ${recordingTime.value}',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
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
}