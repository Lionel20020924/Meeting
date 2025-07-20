import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/profile_service.dart';
import '../services/volcano_engine/voice_separation_service.dart';
import '../services/audio_upload_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Voice Separation Test Utility
/// This utility helps diagnose voice separation issues by running tests
/// and displaying detailed results
class VoiceSeparationTest {
  static final _uploadService = AudioUploadService();
  
  static final _separationService = VoiceSeparationService(
    appKey: dotenv.env['VOICE_SEPARATION_APP_KEY'] ?? '',
    accessKey: dotenv.env['VOICE_SEPARATION_ACCESS_KEY'] ?? '',
  );

  /// Run a comprehensive voice separation test
  static Future<VoiceSeparationTestResult> runTest({
    required List<int> audioData,
    bool showDialog = true,
  }) async {
    final result = VoiceSeparationTestResult();
    
    try {
      // Show progress dialog if requested
      if (showDialog) {
        Get.dialog(
          _TestProgressDialog(result: result),
          barrierDismissible: false,
        );
      }
      
      // Step 1: Check Voice Separation Setting
      result.updateStep(VoiceSeparationTestStep.checkingSettings);
      final profile = await ProfileService.loadProfile();
      final isEnabled = profile['meetingPreferences']?['enableVoiceSeparation'] ?? false;
      result.voiceSeparationEnabled = isEnabled;
      
      if (!isEnabled) {
        result.updateStep(VoiceSeparationTestStep.completed);
        result.error = 'Voice separation is disabled in settings';
        return result;
      }
      
      // Step 2: Upload Audio to TOS
      result.updateStep(VoiceSeparationTestStep.uploadingAudio);
      final uploadStartTime = DateTime.now();
      
      try {
        // Create a temporary file from audio data
        final tempDir = await Directory.systemTemp.createTemp('voice_test');
        final tempFile = File('${tempDir.path}/test_audio.wav');
        await tempFile.writeAsBytes(audioData);
        
        final audioUrl = await _uploadService.uploadAudioFile(tempFile);
        result.uploadDuration = DateTime.now().difference(uploadStartTime);
        result.audioUrl = audioUrl;
        result.uploadSuccess = true;
        
        // Clean up temp file
        try {
          await tempFile.delete();
          await tempDir.delete();
        } catch (_) {}
      } catch (e) {
        result.uploadSuccess = false;
        result.error = 'Upload failed: $e';
        result.updateStep(VoiceSeparationTestStep.completed);
        return result;
      }
      
      // Step 3: Submit Voice Separation Task
      result.updateStep(VoiceSeparationTestStep.submittingTask);
      final submitStartTime = DateTime.now();
      
      try {
        final taskId = await _separationService.submitSeparationTask(
          audioUrl: result.audioUrl!,
          separationType: 'speaker',
          enableDenoising: true,
        );
        result.taskId = taskId;
        result.submitSuccess = true;
        result.submitDuration = DateTime.now().difference(submitStartTime);
      } catch (e) {
        result.submitSuccess = false;
        result.error = 'Submit failed: $e';
        result.updateStep(VoiceSeparationTestStep.completed);
        return result;
      }
      
      // Step 4: Wait for Processing
      result.updateStep(VoiceSeparationTestStep.processing);
      final processStartTime = DateTime.now();
      
      try {
        final separationResult = await _separationService.waitForResult(
          result.taskId!,
          timeout: const Duration(minutes: 3),
        );
        
        result.processingDuration = DateTime.now().difference(processStartTime);
        result.processingSuccess = true;
        result.numberOfTracks = separationResult.tracks?.length ?? 0;
        result.tracks = separationResult.tracks;
        
        // Log track details
        if (Get.isLogEnable) {
          Get.log('=== Voice Separation Test Results ===');
          Get.log('Number of tracks found: ${result.numberOfTracks}');
          separationResult.tracks?.forEach((track) {
            Get.log('Track: ${track.friendlyName}');
            Get.log('  Type: ${track.trackType}');
            Get.log('  URL: ${track.downloadUrl}');
          });
        }
      } catch (e) {
        result.processingSuccess = false;
        result.error = 'Processing failed: $e';
        result.updateStep(VoiceSeparationTestStep.completed);
        return result;
      }
      
      // Step 5: Test Complete
      result.updateStep(VoiceSeparationTestStep.completed);
      result.success = true;
      
    } catch (e) {
      result.error = 'Unexpected error: $e';
      result.updateStep(VoiceSeparationTestStep.completed);
    } finally {
      if (showDialog && Get.isDialogOpen == true) {
        await Future.delayed(const Duration(seconds: 2));
        Get.back();
      }
    }
    
    return result;
  }
  
  /// Show test results in a dialog
  static void showResults(VoiceSeparationTestResult result) {
    Get.dialog(
      AlertDialog(
        title: Text(
          result.success ? 'Voice Separation Test Passed' : 'Voice Separation Test Failed',
          style: TextStyle(
            color: result.success ? Colors.green : Colors.red,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultRow('Voice Separation Enabled', result.voiceSeparationEnabled),
              if (result.audioUrl != null)
                _buildResultRow('Audio Upload', result.uploadSuccess, 
                  detail: '${result.uploadDuration?.inSeconds ?? 0}s'),
              if (result.taskId != null)
                _buildResultRow('Task Submission', result.submitSuccess,
                  detail: '${result.submitDuration?.inSeconds ?? 0}s'),
              if (result.processingDuration != null)
                _buildResultRow('Processing', result.processingSuccess,
                  detail: '${result.processingDuration?.inSeconds ?? 0}s'),
              if (result.numberOfTracks > 0)
                _buildResultRow('Tracks Found', true,
                  detail: '${result.numberOfTracks} speakers'),
              if (result.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Error: ${result.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (result.tracks != null && result.tracks!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Detected Speakers:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.tracks!.map((track) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• ${track.friendlyName}'),
                )),
              ],
            ],
          ),
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
  
  static Widget _buildResultRow(String label, bool? success, {String? detail}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            success == true ? Icons.check_circle : Icons.cancel,
            color: success == true ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          if (detail != null)
            Text(detail, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Progress dialog for voice separation test
class _TestProgressDialog extends StatelessWidget {
  final VoiceSeparationTestResult result;
  
  const _TestProgressDialog({required this.result});
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Testing Voice Separation'),
      content: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_getStepText(result.currentStep.value)),
          if (result.currentStep.value == VoiceSeparationTestStep.processing)
            const Text('This may take up to 1 minute...', 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      )),
    );
  }
  
  String _getStepText(VoiceSeparationTestStep step) {
    switch (step) {
      case VoiceSeparationTestStep.checkingSettings:
        return 'Checking settings...';
      case VoiceSeparationTestStep.uploadingAudio:
        return 'Uploading audio to cloud...';
      case VoiceSeparationTestStep.submittingTask:
        return 'Submitting voice separation task...';
      case VoiceSeparationTestStep.processing:
        return 'Processing audio (speaker detection)...';
      case VoiceSeparationTestStep.completed:
        return 'Test completed';
    }
  }
}

/// Test steps enum
enum VoiceSeparationTestStep {
  checkingSettings,
  uploadingAudio,
  submittingTask,
  processing,
  completed,
}

/// Test result class
class VoiceSeparationTestResult {
  final currentStep = VoiceSeparationTestStep.checkingSettings.obs;
  
  bool voiceSeparationEnabled = false;
  bool uploadSuccess = false;
  bool submitSuccess = false;
  bool processingSuccess = false;
  bool success = false;
  
  String? audioUrl;
  String? taskId;
  String? error;
  
  Duration? uploadDuration;
  Duration? submitDuration;
  Duration? processingDuration;
  
  int numberOfTracks = 0;
  List<SeparatedTrack>? tracks;
  
  void updateStep(VoiceSeparationTestStep step) {
    currentStep.value = step;
  }
}