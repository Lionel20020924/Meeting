import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  test('Debug TOS credentials', () {
    print('\n=== TOS Credentials Debug ===');
    
    // Access Key ID
    final accessKeyId = dotenv.env['TOS_ACCESS_KEY_ID'] ?? '';
    print('Access Key ID: $accessKeyId');
    print('Access Key ID length: ${accessKeyId.length}');
    
    // Secret Access Key
    final secretKeyEncoded = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
    print('\nSecret Key (Base64): ${secretKeyEncoded.substring(0, 20)}...');
    print('Secret Key (Base64) length: ${secretKeyEncoded.length}');
    
    // Try to decode
    try {
      final decoded = base64Decode(secretKeyEncoded);
      print('Decoded bytes length: ${decoded.length}');
      
      final decodedString = utf8.decode(decoded);
      print('Decoded string: ${decodedString.substring(0, 10)}...');
      print('Decoded string length: ${decodedString.length}');
      
      // Always try second decode since the length suggests it's still Base64
      print('\nTrying second decode...');
      try {
        // Add padding if needed
        var paddedString = decodedString;
        final remainder = paddedString.length % 4;
        if (remainder != 0) {
          paddedString += '=' * (4 - remainder);
          print('Added padding: ${4 - remainder} equals signs');
        }
        
        final secondDecode = base64Decode(paddedString);
        final secondString = utf8.decode(secondDecode);
        print('Second decoded string: ${secondString.substring(0, 10)}...');
        print('Second decoded string length: ${secondString.length}');
        print('Second decoded looks like a valid secret key: ${secondString.length == 32}');
        
        // Also try as hex string
        print('\nInterpreting as hex string:');
        print('Full decoded: $decodedString');
        print('This appears to be a 32-byte hex-encoded key');
      } catch (e) {
        print('Second decode failed: $e');
      }
    } catch (e) {
      print('Decode failed: $e');
    }
    
    // Other configs
    print('\nOther configurations:');
    print('Endpoint: ${dotenv.env['TOS_ENDPOINT']}');
    print('Bucket: ${dotenv.env['TOS_BUCKET_NAME']}');
    print('Region: ${dotenv.env['TOS_REGION']}');
  });
}