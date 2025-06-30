import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  test('Test simple TOS request with minimal headers', () async {
    // Decode credentials
    final accessKeyId = dotenv.env['TOS_ACCESS_KEY_ID'] ?? '';
    var secretKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
    
    // Double decode secret key
    try {
      final firstDecode = base64Decode(secretKey);
      var decodedString = utf8.decode(firstDecode);
      
      // Add padding
      final remainder = decodedString.length % 4;
      if (remainder != 0) {
        decodedString += '=' * (4 - remainder);
      }
      
      // Second decode
      final secondDecode = base64Decode(decodedString);
      final hexString = utf8.decode(secondDecode);
      
      // Convert hex to bytes
      if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexString) && hexString.length == 32) {
        final bytes = <int>[];
        for (int i = 0; i < hexString.length; i += 2) {
          bytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
        }
        secretKey = String.fromCharCodes(bytes);
        print('Secret key decoded: ${bytes.length} bytes');
      }
    } catch (e) {
      print('Failed to decode secret key: $e');
    }
    
    // Test with a simple HEAD request first
    final bucket = dotenv.env['TOS_BUCKET_NAME'] ?? 'meetingly';
    final endpoint = dotenv.env['TOS_ENDPOINT'] ?? 'tos-s3-cn-beijing.volces.com';
    final region = dotenv.env['TOS_REGION'] ?? 'cn-beijing';
    
    final now = DateTime.now().toUtc();
    final dateStamp = DateFormat('yyyyMMdd').format(now);
    final amzDate = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
    
    print('\n=== Simple TOS Request Test ===');
    print('Access Key ID: $accessKeyId');
    print('Region: $region');
    print('Date: $amzDate');
    
    // Try a simple bucket listing
    final host = '$bucket.$endpoint';
    final url = 'https://$host/';
    
    // Create minimal headers
    final headers = {
      'Host': host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', // empty payload
    };
    
    // Build canonical request
    final method = 'GET';
    final canonicalUri = '/';
    final canonicalQueryString = '';
    final canonicalHeaders = headers.entries
        .map((e) => '${e.key.toLowerCase()}:${e.value}')
        .toList()
        ..sort();
    final canonicalHeadersString = canonicalHeaders.join('\n');
    final signedHeaders = headers.keys.map((k) => k.toLowerCase()).toList()..sort();
    final signedHeadersString = signedHeaders.join(';');
    
    final canonicalRequest = [
      method,
      canonicalUri,
      canonicalQueryString,
      canonicalHeadersString,
      '',
      signedHeadersString,
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    ].join('\n');
    
    print('\nCanonical Request:');
    print(canonicalRequest);
    
    // Create string to sign
    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final stringToSign = [
      algorithm,
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');
    
    print('\nString to Sign:');
    print(stringToSign);
    
    // Calculate signature
    List<int> hmacSha256(dynamic key, String data) {
      final keyBytes = key is String ? utf8.encode(key) : key as List<int>;
      final hmac = Hmac(sha256, keyBytes);
      return hmac.convert(utf8.encode(data)).bytes;
    }
    
    String hmacSha256Hex(List<int> key, String data) {
      final hmac = Hmac(sha256, key);
      return hmac.convert(utf8.encode(data)).toString();
    }
    
    final kDate = hmacSha256('AWS4$secretKey', dateStamp);
    final kRegion = hmacSha256(kDate, region);
    final kService = hmacSha256(kRegion, 's3');
    final kSigning = hmacSha256(kService, 'aws4_request');
    final signature = hmacSha256Hex(kSigning, stringToSign);
    
    print('\nSignature: $signature');
    
    // Build Authorization header
    final authorization = '$algorithm Credential=$accessKeyId/$credentialScope, SignedHeaders=$signedHeadersString, Signature=$signature';
    
    // Make request
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ...headers,
        'Authorization': authorization,
      },
    );
    
    print('\nResponse Status: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    if (response.statusCode != 200) {
      print('Response Body: ${response.body}');
    }
  });
}