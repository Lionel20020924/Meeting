import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:meeting/app/services/transcription_service.dart';

void main() {
  setUpAll(() async {
    // Load environment variables for testing
    await dotenv.load(fileName: '.env');
  });

  group('Volcano Engine Integration Tests', () {
    test('Check available services', () async {
      final services = await TranscriptionService.getAvailableServices();
      
      print('Available services:');
      services.forEach((service, isAvailable) {
        print('  $service: $isAvailable');
      });
      
      expect(services, isA<Map<String, bool>>());
      expect(services.containsKey('volcano'), true);
      expect(services.containsKey('whisperx'), true);
      expect(services.containsKey('openai'), true);
    });
    
    test('Get preferred provider', () async {
      final provider = await TranscriptionService.getPreferredProvider();
      
      print('Preferred provider: $provider');
      
      // The preferred provider depends on which services are configured
      if (provider != null) {
        expect(
          provider, 
          anyOf([
            TranscriptionProvider.volcano,
            TranscriptionProvider.whisperx,
            TranscriptionProvider.openai,
          ]),
        );
      }
    });
  });
}