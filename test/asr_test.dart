import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:meeting/app/services/audio_upload_service.dart';
import 'package:meeting/app/services/volcano_engine/asr_service.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    // Enable GetX logging for debugging
    Get.config(enableLog: true);
  });

  group('ASR Service Tests', () {
    test('Test ASR submission with fixed headers', () async {
      // Create ASR service
      final appKey = dotenv.env['VOLCANO_APP_KEY'] ?? '';
      final accessKey = dotenv.env['VOLCANO_ACCESS_KEY'] ?? '';
      
      print('ASR Service Configuration:');
      print('  App Key: ${appKey.isNotEmpty ? '${appKey.substring(0, 10)}...' : 'MISSING'}');
      print('  Access Key: ${accessKey.isNotEmpty ? '${accessKey.substring(0, 10)}...' : 'MISSING'}');
      
      final asrService = VolcanoASRService(
        appKey: appKey,
        accessKey: accessKey,
      );
      
      // Create a test audio file
      final testFile = File('test_audio_asr.m4a');
      await testFile.writeAsBytes(utf8.encode('This is a test audio file for ASR'));
      
      try {
        // Upload file first
        final uploadService = AudioUploadService();
        print('\nUploading test file...');
        final audioUrl = await uploadService.uploadAudioFile(testFile);
        print('Upload successful: $audioUrl');
        
        // Submit ASR task
        print('\nSubmitting ASR task...');
        final taskId = await asrService.submitASRTask(
          audioUrl: audioUrl,
          language: 'zh-CN',
        );
        
        print('ASR task submitted successfully!');
        print('Task ID: $taskId');
        
        expect(taskId, isNotEmpty);
        
        // Query task status
        print('\nQuerying task status...');
        final status = await asrService.queryTaskStatus(taskId);
        print('Task status: ${status.status}');
        
      } catch (e) {
        print('\nASR test failed:');
        print('Error: $e');
        print('Type: ${e.runtimeType}');
        
        // Provide diagnostic information
        if (e.toString().contains('45000000')) {
          print('\nDiagnosis: Still missing required headers');
          print('Check if all required headers are included');
        } else if (e.toString().contains('signature')) {
          print('\nDiagnosis: Signature verification failed');
          print('The signature algorithm might need adjustment');
        }
        
        rethrow;
      } finally {
        // Clean up
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}