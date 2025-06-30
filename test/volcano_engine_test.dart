import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:meeting/app/services/transcription_service.dart';

void main() {
  setUpAll(() async {
    // Load environment variables for testing
    await dotenv.load(fileName: '.env');
  });

  group('Volcano Engine Integration Tests', () {
    test('Check if service is available', () async {
      final isAvailable = await TranscriptionService.isAvailable();
      
      print('Volcano Engine service available: $isAvailable');
      
      expect(isAvailable, isA<bool>());
    });
    
    test('Get service status', () async {
      final status = await TranscriptionService.getServiceStatus();
      
      print('Service status:');
      status.forEach((key, value) {
        print('  $key: $value');
      });
      
      expect(status, isA<Map<String, dynamic>>());
      expect(status['provider'], equals('volcano'));
      expect(status.containsKey('available'), true);
      expect(status.containsKey('configured'), true);
    });
  });
}