import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  test('Check if secret key is hex encoded', () {
    final encodedKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
    
    // First decode
    final firstDecode = base64Decode(encodedKey);
    var decodedString = utf8.decode(firstDecode);
    print('First decode: $decodedString');
    
    // Add padding
    final remainder = decodedString.length % 4;
    if (remainder != 0) {
      decodedString += '=' * (4 - remainder);
    }
    
    // Second decode
    final secondDecode = base64Decode(decodedString);
    final secondString = utf8.decode(secondDecode);
    print('Second decode as UTF-8: $secondString');
    print('Second decode length: ${secondString.length}');
    
    // Check if it's valid hex
    final hexPattern = RegExp(r'^[0-9a-fA-F]+$');
    if (hexPattern.hasMatch(secondString)) {
      print('\nThis appears to be a hex-encoded string!');
      print('Hex string: $secondString');
      print('Would decode to ${secondString.length / 2} bytes');
      
      // Try to interpret as hex
      final bytes = <int>[];
      for (int i = 0; i < secondString.length; i += 2) {
        final hex = secondString.substring(i, i + 2);
        bytes.add(int.parse(hex, radix: 16));
      }
      
      print('Hex decoded to ${bytes.length} bytes');
      print('First few bytes: ${bytes.take(10).toList()}');
      
      // Try as ASCII
      try {
        final asciiString = String.fromCharCodes(bytes);
        print('As ASCII: ${asciiString.replaceAll(RegExp(r'[^\x20-\x7E]'), '?')}');
      } catch (e) {
        print('Cannot convert to ASCII');
      }
    } else {
      print('\nNot a hex string, contains non-hex characters');
    }
  });
}