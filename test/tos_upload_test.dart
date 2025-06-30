import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:meeting/app/services/audio_upload_service.dart';

void main() {
  setUpAll(() async {
    // Load environment variables for testing
    await dotenv.load(fileName: '.env');
  });

  group('TOS Upload Tests', () {
    test('Test MinIO client connection and upload', () async {
      final uploadService = AudioUploadService();
      
      // Create a small test file
      final testFile = File('test_audio.m4a');
      await testFile.writeAsBytes(utf8.encode('This is a test audio file'));
      
      try {
        print('\n=== TOS Upload Test ===');
        print('Endpoint: ${dotenv.env['TOS_ENDPOINT']}');
        print('Bucket: ${dotenv.env['TOS_BUCKET_NAME']}');
        print('Region: ${dotenv.env['TOS_REGION']}');
        print('Access Key ID: ${dotenv.env['TOS_ACCESS_KEY_ID']?.substring(0, 10)}...');
        
        final secretKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
        print('Secret Key (Base64): ${secretKey.substring(0, 20)}...');
        
        // Test Base64 decoding
        try {
          final decoded = base64Decode(secretKey);
          final decodedString = utf8.decode(decoded);
          print('Secret Key (Decoded): ${decodedString.substring(0, 10)}...');
        } catch (e) {
          print('Secret Key decoding failed: $e');
        }
        
        print('\nAttempting upload...');
        
        // Attempt upload
        final url = await uploadService.uploadAudioFile(testFile);
        
        print('Upload successful!');
        print('URL: $url');
        
        expect(url, isNotEmpty);
        expect(url, contains('meetingly'));
        
      } catch (e) {
        print('Upload failed with error: $e');
        print('Error type: ${e.runtimeType}');
        print('Stack trace:');
        print(StackTrace.current);
        
        // Re-throw to fail the test
        rethrow;
      } finally {
        // Clean up
        if (await testFile.exists()) {
          await testFile.delete();
        }
        uploadService.dispose();
      }
    });
  });
}