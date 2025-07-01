import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../audio_upload_service.dart';
import 'asr_service.dart';
import '../doubao_ai_service.dart';
import 'package:get/get.dart';

/// 转录结果类
class VolcanoTranscriptionResult {
  final String text;
  final String? language;
  final List<VolcanoTranscriptionSegment>? segments;
  final MeetingSummary? summary;

  VolcanoTranscriptionResult({
    required this.text,
    this.language,
    this.segments,
    this.summary,
  });
}

/// 转录片段
class VolcanoTranscriptionSegment {
  final String text;
  final double startTime;
  final double endTime;
  final String? speakerId;
  final double? confidence;

  VolcanoTranscriptionSegment({
    required this.text,
    required this.startTime,
    required this.endTime,
    this.speakerId,
    this.confidence,
  });
}

/// 火山引擎转录服务实现
class VolcanoTranscriptionService {
  late final AudioUploadService _uploadService;
  late final VolcanoASRService _asrService;
  
  VolcanoTranscriptionService() {
    // 初始化服务
    _uploadService = AudioUploadService();
    
    _asrService = VolcanoASRService(
      appKey: dotenv.env['VOLCANO_APP_KEY'] ?? '',
      accessKey: dotenv.env['VOLCANO_ACCESS_KEY'] ?? '',
    );
  }

  String get serviceName => 'Volcano Engine ASR (BigModel)';

  Future<bool> isAvailable() async {
    // 检查必要的配置是否存在
    return dotenv.env['VOLCANO_APP_KEY']?.isNotEmpty == true &&
           dotenv.env['VOLCANO_ACCESS_KEY']?.isNotEmpty == true &&
           dotenv.env['TOS_ACCESS_KEY_ID']?.isNotEmpty == true &&
           dotenv.env['TOS_SECRET_ACCESS_KEY']?.isNotEmpty == true;
  }

  /// 执行音频转录
  Future<VolcanoTranscriptionResult> transcribe(
    File audioFile, {
    bool generateSummary = true,
    String? meetingTitle,
    DateTime? meetingDate,
  }) async {
    try {
      // 1. 上传音频文件到 TOS
      if (Get.isLogEnable) {
        Get.log('Uploading audio file to TOS...');
      }
      
      final audioUrl = await _uploadService.uploadAudioFile(audioFile);
      
      if (Get.isLogEnable) {
        Get.log('Audio uploaded successfully. Starting ASR...');
      }
      
      // 2. 提交 ASR 任务
      final taskId = await _asrService.submitASRTask(
        audioUrl: audioUrl,
        language: 'zh-CN',
        enableDiarization: true,
        enableIntelligentSegment: true,
        enablePunctuation: true,
        enableTimestamp: true,
      );
      
      if (Get.isLogEnable) {
        Get.log('ASR task submitted: $taskId');
      }
      
      // 3. 等待并获取结果
      final asrResult = await _asrService.waitForResult(
        taskId,
        timeout: const Duration(minutes: 10),
      );
      
      if (Get.isLogEnable) {
        Get.log('ASR completed successfully');
      }
      
      // 4. 转换结果格式
      final segments = _convertSegments(asrResult.segments);
      
      // 首先尝试从metadata中获取转录文本
      String fullText = '';
      if (asrResult.metadata != null && asrResult.metadata!['transcript_text'] != null) {
        fullText = asrResult.metadata!['transcript_text'] as String;
      }
      
      // 如果metadata中没有文本，从segments拼接
      if (fullText.isEmpty && segments.isNotEmpty) {
        fullText = segments.map((s) => s.text).join(' ');
      }
      
      if (Get.isLogEnable) {
        Get.log('Transcription text extracted: ${fullText.substring(0, fullText.length > 100 ? 100 : fullText.length)}...');
      }
      
      // 5. 生成会议摘要（如果需要）
      MeetingSummary? summary;
      if (generateSummary && dotenv.env['ARK_API_KEY']?.isNotEmpty == true) {
        try {
          if (Get.isLogEnable) {
            Get.log('Generating meeting summary with Doubao AI...');
          }
          
          summary = await DoubaoAIService.generateMeetingSummary(
            transcriptText: fullText,
            segments: segments.map((s) => TranscriptSegment(
              text: s.text,
              speakerId: s.speakerId,
              startTime: s.startTime,
              endTime: s.endTime,
            )).toList(),
            meetingTitle: meetingTitle,
            meetingDate: meetingDate,
          );
          
          if (Get.isLogEnable) {
            Get.log('Meeting summary generated successfully');
          }
        } catch (e) {
          if (Get.isLogEnable) {
            Get.log('Failed to generate summary: $e');
          }
        }
      }
      
      // 6. 清理：删除 TOS 中的音频文件（可选）
      try {
        final objectKey = audioUrl.split('/').last;
        await _uploadService.deleteAudioFile(objectKey);
      } catch (e) {
        // 忽略删除错误
      }
      
      return VolcanoTranscriptionResult(
        text: fullText,
        language: 'zh-CN',
        segments: segments,
        summary: summary,
      );
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error in Volcano transcription: $e');
      }
      rethrow;
    }
  }

  /// 转换 ASR 片段格式
  List<VolcanoTranscriptionSegment> _convertSegments(List<ASRSegment>? asrSegments) {
    if (asrSegments == null || asrSegments.isEmpty) {
      return [];
    }
    
    return asrSegments.map((segment) => VolcanoTranscriptionSegment(
      text: segment.text,
      startTime: segment.startTime,
      endTime: segment.endTime,
      speakerId: segment.speakerId,
      confidence: segment.confidence,
    )).toList();
  }
  
  /// 清理资源
  void dispose() {
    _uploadService.dispose();
  }
}