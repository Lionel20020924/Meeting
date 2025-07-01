import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:meeting/app/services/volcano_engine/asr_service.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    // Enable GetX logging for debugging
    Get.config(enableLog: true);
  });

  test('Debug ASR URL and Headers', () async {
    // Create ASR service
    final appKey = dotenv.env['VOLCANO_APP_KEY'] ?? '';
    final accessKey = dotenv.env['VOLCANO_ACCESS_KEY'] ?? '';
    
    print('\n===== ASR SERVICE DEBUG TEST =====');
    print('App Key: ${appKey.isNotEmpty ? '${appKey.substring(0, min(10, appKey.length))}...' : 'MISSING'}');
    print('Access Key: ${accessKey.isNotEmpty ? '${accessKey.substring(0, min(10, accessKey.length))}...' : 'MISSING'}');
    
    if (appKey.isEmpty || accessKey.isEmpty) {
      print('\nERROR: Missing required environment variables!');
      print('Please ensure VOLCANO_APP_KEY and VOLCANO_ACCESS_KEY are set in .env file');
      return;
    }
    
    final asrService = VolcanoASRService(
      appKey: appKey,
      accessKey: accessKey,
    );
    
    try {
      // Use a test audio URL (you can replace this with a real URL)
      const testAudioUrl = 'https://example.com/test-audio.m4a';
      
      print('\n===== SUBMITTING ASR TASK =====');
      print('Test Audio URL: $testAudioUrl');
      
      // This will trigger the debug logging in the ASR service
      final taskId = await asrService.submitASRTask(
        audioUrl: testAudioUrl,
        language: 'zh-CN',
      );
      
      print('\n===== ASR TASK SUBMITTED =====');
      print('Task ID: $taskId');
      
    } catch (e) {
      print('\n===== ASR TEST FAILED =====');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      
      // Parse error message for more details
      final errorString = e.toString();
      if (errorString.contains('app key not found')) {
        print('\nDIAGNOSIS: The API is not receiving the app key properly');
        print('Possible issues:');
        print('1. The app key parameter name might be incorrect (try "app_key" instead of "appkey")');
        print('2. The API might expect the app key in a different header');
        print('3. The API endpoint might be incorrect');
      }
      
      // Don't rethrow in debug test
    }
  });
}

// Helper function for min
int min(int a, int b) => a < b ? a : b;