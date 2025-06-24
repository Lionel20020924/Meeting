import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'whisperx_service.dart';
import 'openai_service.dart';

enum TranscriptionProvider { whisperx, openai }

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
  /// Tries WhisperX first, falls back to OpenAI if unavailable
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
      }
    }

    // Auto-selection: try WhisperX first, fallback to OpenAI
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
  static Map<String, bool> getAvailableServices() {
    return {
      'whisperx': dotenv.env['REPLICATE_API_KEY']?.isNotEmpty == true,
      'openai': dotenv.env['OPENAI_API_KEY']?.isNotEmpty == true,
    };
  }

  /// Get the preferred transcription provider based on available configuration
  static TranscriptionProvider? getPreferredProvider() {
    final services = getAvailableServices();
    
    if (services['whisperx'] == true) {
      return TranscriptionProvider.whisperx;
    } else if (services['openai'] == true) {
      return TranscriptionProvider.openai;
    }
    
    return null;
  }
}