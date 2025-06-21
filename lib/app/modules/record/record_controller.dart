import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';

class RecordController extends GetxController {
  final titleController = TextEditingController();
  
  final isRecording = false.obs;
  final isPaused = false.obs;
  final recordingTime = '00:00'.obs;
  final notes = <Map<String, String>>[].obs;
  
  Timer? _timer;
  int _seconds = 0;
  bool _animationToggle = false;
  
  @override
  void onClose() {
    titleController.dispose();
    _timer?.cancel();
    super.onClose();
  }

  void toggleRecording() {
    if (isRecording.value) {
      // Show dialog to save recording
      _showSaveDialog();
    } else {
      startRecording();
    }
  }

  void startRecording() {
    // TODO: Implement actual recording logic
    isRecording.value = true;
    _startTimer();
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

  void _saveRecording() {
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
    
    // TODO: Implement stop recording logic
    Get.back(); // Close dialog
    
    // Navigate to summary page after recording
    Get.toNamed(Routes.SUMMARY, arguments: {
      'recordingId': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': titleController.text,
      'duration': recordingTime.value,
      'notes': notes.toList(),
    });
    
    // Reset state
    _resetRecording();
  }

  void _discardRecording() {
    // TODO: Implement discard recording logic
    _resetRecording();
  }

  void _resetRecording() {
    isRecording.value = false;
    isPaused.value = false;
    _timer?.cancel();
    _seconds = 0;
    recordingTime.value = '00:00';
    titleController.clear();
    notes.clear();
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

  void togglePause() {
    isPaused.value = !isPaused.value;
    if (isPaused.value) {
      _timer?.cancel();
    } else {
      _startTimer();
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