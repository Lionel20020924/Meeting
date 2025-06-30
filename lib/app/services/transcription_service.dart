import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'whisperx_service.dart';
import 'openai_service.dart';
import 'volcano_engine/volcano_transcription_service.dart';

enum TranscriptionProvider { whisperx, openai, volcano }

class TranscriptionResult {
  final String text;
  final List<WhisperXSegment>? segments;
  final String? detectedLanguage;
  final TranscriptionProvider provider;

  TranscriptionResult({
    required this.text,
    this.segments,
    this.detectedLanguage,
    required this.provider,
  });
}

class TranscriptionService {
  /// Transcribe audio using the best available service
  /// Priority: Volcano -> WhisperX -> OpenAI
  static Future<TranscriptionResult> transcribeAudio({
    required Uint8List audioData,
    String? language = 'zh',
    TranscriptionProvider? provider,
  }) async {
    // If provider is specified, use only that provider
    if (provider != null) {
      switch (provider) {
        case TranscriptionProvider.whisperx:
          return _transcribeWithWhisperX(audioData, language);
        case TranscriptionProvider.openai:
          return _transcribeWithOpenAI(audioData, language);
        case TranscriptionProvider.volcano:
          return _transcribeWithVolcano(audioData, language);
      }
    }

    // Auto-selection: try Volcano first, then WhisperX, finally OpenAI
    // Try Volcano Engine first
    try {
      if (await _isVolcanoAvailable()) {
        return await _transcribeWithVolcano(audioData, language);
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Volcano failed: $e');
      }
    }
    
    // Try WhisperX
    try {
      return await _transcribeWithWhisperX(audioData, language);
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('WhisperX failed, falling back to OpenAI: $e');
      }
      return await _transcribeWithOpenAI(audioData, language);
    }
  }

  static Future<TranscriptionResult> _transcribeWithWhisperX(
    Uint8List audioData,
    String? language,
  ) async {
    // Check if Replicate API key is available
    if (dotenv.env['REPLICATE_API_KEY'] == null || 
        dotenv.env['REPLICATE_API_KEY']!.isEmpty) {
      throw Exception('Replicate API key not configured');
    }

    final result = await WhisperXService.transcribeAudio(
      audioData: audioData,
      language: language,
      diarization: false, // Disable diarization for faster processing
      alignOutput: false, // Disable alignment for faster processing
    );

    return TranscriptionResult(
      text: result.fullText,
      segments: result.segments,
      detectedLanguage: result.detectedLanguage,
      provider: TranscriptionProvider.whisperx,
    );
  }

  static Future<TranscriptionResult> _transcribeWithOpenAI(
    Uint8List audioData,
    String? language,
  ) async {
    // Check if OpenAI API key is available
    if (dotenv.env['OPENAI_API_KEY'] == null || 
        dotenv.env['OPENAI_API_KEY']!.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    final text = await OpenAIService.transcribeAudio(
      audioData: audioData,
      language: language ?? 'zh',
    );

    return TranscriptionResult(
      text: text,
      segments: null,
      detectedLanguage: language,
      provider: TranscriptionProvider.openai,
    );
  }
  
  static Future<bool> _isVolcanoAvailable() async {
    final service = VolcanoTranscriptionService();
    return await service.isAvailable();
  }
  
  static Future<TranscriptionResult> _transcribeWithVolcano(
    Uint8List audioData,
    String? language,
  ) async {
    final service = VolcanoTranscriptionService();
    
    // 创建临时文件
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, 'temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a'));
    await tempFile.writeAsBytes(audioData);
    
    try {
      final result = await service.transcribe(tempFile);
      
      // 转换为兼容格式
      return TranscriptionResult(
        text: result.text,
        segments: result.segments?.map((s) => WhisperXSegment(
          start: s.startTime,
          end: s.endTime,
          text: s.text,
        )).toList(),
        detectedLanguage: result.language,
        provider: TranscriptionProvider.volcano,
      );
    } finally {
      // 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Simple transcription method that returns just the text
  static Future<String> transcribeAudioSimple({
    required Uint8List audioData,
    String? language = 'zh',
    TranscriptionProvider? provider,
  }) async {
    final result = await transcribeAudio(
      audioData: audioData,
      language: language,
      provider: provider,
    );
    return result.text;
  }

  /// Check which transcription services are available
  static Future<Map<String, bool>> getAvailableServices() async {
    final volcanoService = VolcanoTranscriptionService();
    return {
      'volcano': await volcanoService.isAvailable(),
      'whisperx': dotenv.env['REPLICATE_API_KEY']?.isNotEmpty == true,
      'openai': dotenv.env['OPENAI_API_KEY']?.isNotEmpty == true,
    };
  }

  /// Get the preferred transcription provider based on available configuration
  static Future<TranscriptionProvider?> getPreferredProvider() async {
    final services = await getAvailableServices();
    
    if (services['volcano'] == true) {
      return TranscriptionProvider.volcano;
    } else if (services['whisperx'] == true) {
      return TranscriptionProvider.whisperx;
    } else if (services['openai'] == true) {
      return TranscriptionProvider.openai;
    }
    
    return null;
  }
}