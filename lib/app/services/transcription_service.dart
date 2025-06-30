import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'volcano_engine/volcano_transcription_service.dart';

class TranscriptionResult {
  final String text;
  final List<VolcanoTranscriptionSegment>? segments;
  final String? detectedLanguage;

  TranscriptionResult({
    required this.text,
    this.segments,
    this.detectedLanguage,
  });
}

class TranscriptionService {
  /// Transcribe audio using Volcano Engine
  static Future<TranscriptionResult> transcribeAudio({
    required Uint8List audioData,
    String? language = 'zh',
  }) async {
    final service = VolcanoTranscriptionService();
    
    // Check if Volcano Engine is available
    if (!await service.isAvailable()) {
      throw Exception('火山引擎转录服务未配置，请检查 API 密钥设置');
    }
    
    // Create temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, 'temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a'));
    await tempFile.writeAsBytes(audioData);
    
    try {
      final result = await service.transcribe(tempFile);
      
      // Convert to compatible format
      return TranscriptionResult(
        text: result.text,
        segments: result.segments,
        detectedLanguage: result.language ?? language,
      );
    } finally {
      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Simple transcription method that returns just the text
  static Future<String> transcribeAudioSimple({
    required Uint8List audioData,
    String? language = 'zh',
  }) async {
    final result = await transcribeAudio(
      audioData: audioData,
      language: language,
    );
    return result.text;
  }

  /// Check if transcription service is available
  static Future<bool> isAvailable() async {
    final volcanoService = VolcanoTranscriptionService();
    return await volcanoService.isAvailable();
  }

  /// Get service status
  static Future<Map<String, dynamic>> getServiceStatus() async {
    final volcanoService = VolcanoTranscriptionService();
    final isAvailable = await volcanoService.isAvailable();
    
    return {
      'provider': 'volcano',
      'name': volcanoService.serviceName,
      'available': isAvailable,
      'configured': dotenv.env['VOLCANO_APP_KEY']?.isNotEmpty == true &&
                   dotenv.env['VOLCANO_ACCESS_KEY']?.isNotEmpty == true &&
                   dotenv.env['TOS_ACCESS_KEY_ID']?.isNotEmpty == true &&
                   dotenv.env['TOS_SECRET_ACCESS_KEY']?.isNotEmpty == true,
    };
  }
}