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

  group('MinIO TOS Upload Tests', () {
    test('Test MinIO connection to TOS', () async {
      final uploadService = AudioUploadService();
      
      // Wait for connection test to complete
      await Future.delayed(const Duration(seconds: 2));
      
      print('\n=== MinIO TOS Connection Test ===');
      print('Testing MinIO client connection to Volcano Engine TOS...');
    });
    
    test('Test MinIO upload to TOS', () async {
      final uploadService = AudioUploadService();
      
      // Create a small test file
      final testFile = File('test_audio_minio.m4a');
      await testFile.writeAsBytes(utf8.encode('This is a test audio file for MinIO upload'));
      
      try {
        print('\n=== MinIO TOS Upload Test ===');
        print('File size: ${testFile.lengthSync()} bytes');
        print('Attempting upload...');
        
        // Monitor upload progress
        uploadService.uploadProgress.listen((progress) {
          print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
        });
        
        // Attempt upload
        final url = await uploadService.uploadAudioFile(testFile);
        
        print('Upload successful!');
        print('URL: $url');
        
        expect(url, isNotEmpty);
        expect(url, contains('meetingly'));
        
      } catch (e) {
        print('Upload failed with error: $e');
        print('Error type: ${e.runtimeType}');
        
        // Provide diagnostic information
        if (e.toString().contains('Forbidden')) {
          print('\nDiagnosis: Access forbidden');
          print('Possible causes:');
          print('1. Secret key format issue');
          print('2. Bucket permissions');
          print('3. MinIO compatibility with TOS');
        } else if (e.toString().contains('SignatureDoesNotMatch')) {
          print('\nDiagnosis: Signature mismatch');
          print('The secret key decoding might be incorrect for MinIO');
        }
        
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
    
    test('Test different secret key formats with MinIO', () async {
      print('\n=== Secret Key Format Test ===');
      
      final encodedKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
      print('Original key (Base64): ${encodedKey.substring(0, 20)}...');
      
      // Test 1: Original Base64 (no decoding)
      print('\nTest 1: Using original Base64 string');
      print('Length: ${encodedKey.length}');
      
      // Test 2: Single Base64 decode
      try {
        final singleDecode = base64Decode(encodedKey);
        final singleString = utf8.decode(singleDecode);
        print('\nTest 2: Single Base64 decode');
        print('Result: ${singleString.substring(0, 20)}...');
        print('Length: ${singleString.length}');
      } catch (e) {
        print('Single decode failed: $e');
      }
      
      // Test 3: Double Base64 decode + hex
      try {
        final firstDecode = base64Decode(encodedKey);
        var decodedString = utf8.decode(firstDecode);
        
        // Add padding if needed
        final remainder = decodedString.length % 4;
        if (remainder != 0) {
          decodedString += '=' * (4 - remainder);
        }
        
        final secondDecode = base64Decode(decodedString);
        final hexString = utf8.decode(secondDecode);
        
        print('\nTest 3: Double Base64 decode');
        print('Hex string: $hexString');
        
        if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexString)) {
          print('Valid hex string detected');
          
          // Convert hex to bytes
          final bytes = <int>[];
          for (int i = 0; i < hexString.length; i += 2) {
            bytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
          }
          
          print('Hex decoded to ${bytes.length} bytes');
          
          // Test if MinIO prefers hex string or binary
          print('\nMinIO might expect:');
          print('1. The hex string itself: $hexString');
          print('2. The binary data (${bytes.length} bytes)');
          print('3. The original Base64: $encodedKey');
        }
      } catch (e) {
        print('Double decode failed: $e');
      }
    });
  });
}