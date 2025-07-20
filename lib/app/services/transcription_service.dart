import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';
import 'volcano_engine/volcano_transcription_service.dart';
import 'volcano_engine/voice_separation_service.dart';

class TranscriptionResult {
  final String text;
  final String? formattedText;
  final List<VolcanoTranscriptionSegment>? segments;
  final String? detectedLanguage;
  final List<SeparatedTrack>? separatedTracks;

  TranscriptionResult({
    required this.text,
    this.formattedText,
    this.segments,
    this.detectedLanguage,
    this.separatedTracks,
  });
}

class TranscriptionService {
  /// Transcribe audio using Volcano Engine
  static Future<TranscriptionResult> transcribeAudio({
    required Uint8List audioData,
    String? language = 'zh',
    bool enableVoiceSeparation = false,
    String separationType = 'speaker',
    int? maxSpeakers,
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
      List<SeparatedTrack>? separatedTracks;
      
      // Perform voice separation if enabled
      if (enableVoiceSeparation) {
        try {
          final separationService = VoiceSeparationService(
            appKey: dotenv.env['VOLCANO_APP_KEY'] ?? '',
            accessKey: dotenv.env['VOLCANO_ACCESS_KEY'] ?? '',
          );
          
          // Upload audio file first (reuse the same upload as transcription)
          final audioUrl = await service.uploadAudioFile(tempFile);
          
          // Submit separation task
          final taskId = await separationService.submitSeparationTask(
            audioUrl: audioUrl,
            separationType: separationType,
            maxSpeakers: maxSpeakers,
            enableDenoising: true,
          );
          
          // Wait for separation result
          final separationResult = await separationService.waitForResult(
            taskId,
            timeout: const Duration(minutes: 5),
          );
          
          separatedTracks = separationResult.tracks;
        } catch (e) {
          // Voice separation failed, continue with normal transcription
          if (Get.isLogEnable) {
            Get.log('Voice separation failed, continuing with normal transcription: $e');
          }
        }
      }
      
      // Transcribe with or without separation
      final result = await service.transcribe(
        tempFile,
        separatedTracks: separatedTracks,
      );
      
      // Convert to compatible format
      return TranscriptionResult(
        text: result.text,
        formattedText: result.formattedText,
        segments: result.segments,
        detectedLanguage: result.language ?? language,
        separatedTracks: separatedTracks,
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