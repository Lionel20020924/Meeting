import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:meeting/app/services/volcano_engine/tos_service.dart';
import 'package:http/http.dart' as http;

void main() {
  setUpAll(() async {
    // Load environment variables for testing
    await dotenv.load(fileName: '.env');
  });

  group('TOS Direct Upload Tests', () {
    test('Test direct TOS upload with proper URL format', () async {
      // Decode the secret key (double Base64 encoded)
      var secretKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
      try {
        // First decode
        final firstDecode = base64Decode(secretKey);
        var decodedString = utf8.decode(firstDecode);
        print('First decode: ${decodedString.substring(0, 10)}... (length: ${decodedString.length})');
        
        // Add padding if needed
        final remainder = decodedString.length % 4;
        if (remainder != 0) {
          decodedString += '=' * (4 - remainder);
        }
        
        // Second decode
        final secondDecode = base64Decode(decodedString);
        final hexString = utf8.decode(secondDecode);
        print('Second decode (hex): $hexString');
        
        // Convert hex to bytes
        if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexString) && hexString.length == 32) {
          final bytes = <int>[];
          for (int i = 0; i < hexString.length; i += 2) {
            bytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
          }
          secretKey = String.fromCharCodes(bytes);
          print('Hex converted to ${bytes.length} bytes');
        } else {
          secretKey = hexString;
        }
        print('Secret key fully decoded');
      } catch (e) {
        print('Failed to decode secret key: $e');
      }
      
      final tosService = TOSService(
        accessKeyId: dotenv.env['TOS_ACCESS_KEY_ID'] ?? '',
        secretAccessKey: secretKey,
        endpoint: dotenv.env['TOS_ENDPOINT'] ?? 'tos-s3-cn-beijing.volces.com',
        bucketName: dotenv.env['TOS_BUCKET_NAME'] ?? 'meetingly',
        region: dotenv.env['TOS_REGION'] ?? 'cn-beijing',
      );
      
      // Create a small test file
      final testFile = File('test_audio_direct.m4a');
      await testFile.writeAsBytes(utf8.encode('This is a test audio file for direct upload'));
      
      try {
        print('\n=== Direct TOS Upload Test ===');
        print('Endpoint: ${dotenv.env['TOS_ENDPOINT']}');
        print('Bucket: ${dotenv.env['TOS_BUCKET_NAME']}');
        print('Region: ${dotenv.env['TOS_REGION']}');
        
        // Attempt upload
        final url = await tosService.uploadFile(testFile);
        
        print('Upload successful!');
        print('URL: $url');
        
        expect(url, isNotEmpty);
        expect(url, contains('meetingly'));
        
      } catch (e) {
        print('Upload failed with error: $e');
        print('Error type: ${e.runtimeType}');
        
        // Re-throw to fail the test
        rethrow;
      } finally {
        // Clean up
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });
    
    test('Test TOS endpoint connectivity', () async {
      final bucket = dotenv.env['TOS_BUCKET_NAME'] ?? 'meetingly';
      final endpoint = dotenv.env['TOS_ENDPOINT'] ?? 'tos-s3-cn-beijing.volces.com';
      
      // Test both URL formats
      final urls = [
        'https://$bucket.$endpoint/',  // Virtual-hosted style
        'https://$endpoint/$bucket/',  // Path style
      ];
      
      print('\n=== Testing TOS Endpoint Connectivity ===');
      
      for (final url in urls) {
        print('\nTesting URL: $url');
        try {
          final response = await http.head(Uri.parse(url));
          print('  Status: ${response.statusCode}');
          print('  Headers: ${response.headers}');
        } catch (e) {
          print('  Error: $e');
        }
      }
    });
  });
}