import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../audio_storage_interface.dart';
import '../audio_storage_factory.dart';
import 'asr_service.dart';
import '../doubao_ai_service.dart';
import '../profile_service.dart';
import 'voice_separation_service.dart';
import 'package:get/get.dart';

/// 转录结果类
class VolcanoTranscriptionResult {
  final String text;
  final String? formattedText;
  final String? language;
  final List<VolcanoTranscriptionSegment>? segments;
  final MeetingSummary? summary;

  VolcanoTranscriptionResult({
    required this.text,
    this.formattedText,
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
  late final AudioStorageInterface _storageService;
  late final VolcanoASRService _asrService;
  
  VolcanoTranscriptionService() {
    // 初始化服务
    _storageService = AudioStorageFactory.getInstance();
    
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

  /// 上传音频文件到TOS并返回URL
  Future<String> uploadAudioFile(File audioFile) async {
    return await _storageService.uploadAudioFile(audioFile);
  }

  /// 执行音频转录
  Future<VolcanoTranscriptionResult> transcribe(
    File audioFile, {
    bool generateSummary = true,
    String? meetingTitle,
    DateTime? meetingDate,
    List<SeparatedTrack>? separatedTracks,
  }) async {
    try {
      // 1. 上传音频文件到 TOS
      if (Get.isLogEnable) {
        Get.log('Uploading audio file to TOS...');
      }
      
      final audioUrl = await _storageService.uploadAudioFile(audioFile, meetingId: meetingTitle);
      
      if (Get.isLogEnable) {
        Get.log('Audio uploaded successfully. Starting ASR...');
      }
      
      // 2. 读取用户的speaker diarization偏好设置
      final profile = await ProfileService.loadProfile();
      final enableSpeakerDiarization = profile['meetingPreferences']?['enableSpeakerDiarization'] ?? true;
      
      if (Get.isLogEnable) {
        Get.log('Speaker diarization enabled: $enableSpeakerDiarization');
      }
      
      // 3. 处理分离的音轨或原始音频
      String taskId;
      List<VolcanoTranscriptionSegment> allSegments = [];
      
      if (separatedTracks != null && separatedTracks.isNotEmpty) {
        // 如果有分离的音轨，分别转录每个音轨
        if (Get.isLogEnable) {
          Get.log('Transcribing ${separatedTracks.length} separated tracks...');
        }
        
        for (int i = 0; i < separatedTracks.length; i++) {
          final track = separatedTracks[i];
          if (Get.isLogEnable) {
            Get.log('Processing track ${i + 1}: ${track.friendlyName}');
          }
          
          // 提交每个音轨的ASR任务
          final trackTaskId = await _asrService.submitASRTask(
            audioUrl: track.downloadUrl,
            language: 'zh-CN',
            enableDiarization: false, // 分离后的音轨不需要再做说话人分离
            enableIntelligentSegment: true,
            enablePunctuation: true,
            enableTimestamp: true,
          );
          
          // 等待结果
          final trackResult = await _asrService.waitForResult(
            trackTaskId,
            timeout: const Duration(minutes: 5),
          );
          
          // 转换并标记说话人ID
          final trackSegments = _convertSegments(
            trackResult.segments,
            speakerIdOverride: track.trackType,
          );
          allSegments.addAll(trackSegments);
        }
        
        // 按时间排序所有片段
        allSegments.sort((a, b) => a.startTime.compareTo(b.startTime));
        
        // 使用第一个任务ID作为主任务ID
        taskId = separatedTracks.first.trackId;
      } else {
        // 没有分离音轨，使用原始音频
        taskId = await _asrService.submitASRTask(
          audioUrl: audioUrl,
          language: 'zh-CN',
          enableDiarization: enableSpeakerDiarization,
          enableIntelligentSegment: true,
          enablePunctuation: true,
          enableTimestamp: true,
        );
      }
      
      if (Get.isLogEnable) {
        Get.log('ASR task submitted: $taskId');
      }
      
      // 4. 如果没有分离音轨，等待原始音频的ASR结果
      if (separatedTracks == null || separatedTracks.isEmpty) {
        final asrResult = await _asrService.waitForResult(
          taskId,
          timeout: const Duration(minutes: 10),
        );
        
        if (Get.isLogEnable) {
          Get.log('ASR completed successfully');
        }
        
        // 转换结果格式
        allSegments = _convertSegments(asrResult.segments);
      }
      
      // 5. 处理转录文本
      String fullText = '';
      String formattedText = '';
      
      // 从segments拼接完整文本
      if (allSegments.isNotEmpty) {
        // 纯文本版本（用于AI摘要等）
        fullText = allSegments.map((s) => s.text).join(' ');
        
        // 格式化文本版本（带说话人标识）
        String? currentSpeaker;
        List<String> formattedLines = [];
        
        if (Get.isLogEnable) {
          Get.log('=== Generating Formatted Text with Speaker Labels ===');
          Get.log('Total segments: ${allSegments.length}');
        }
        
        for (var segment in allSegments) {
          final speakerId = segment.speakerId;
          if (Get.isLogEnable && speakerId != null) {
            Get.log('Segment speaker: $speakerId, text: ${segment.text.substring(0, segment.text.length > 30 ? 30 : segment.text.length)}...');
          }
          
          if (speakerId != null && speakerId != currentSpeaker) {
            // 说话人改变，添加新的说话人标识
            currentSpeaker = speakerId;
            final speakerLabel = _formatSpeakerName(speakerId);
            formattedLines.add('\n$speakerLabel：');
            
            if (Get.isLogEnable) {
              Get.log('Added speaker label: $speakerLabel');
            }
          }
          formattedLines.add(segment.text);
        }
        
        formattedText = formattedLines.join(' ').trim();
        
        if (Get.isLogEnable) {
          Get.log('Formatted text length: ${formattedText.length}');
          Get.log('Formatted text preview: ${formattedText.substring(0, formattedText.length > 200 ? 200 : formattedText.length)}...');
        }
      }
      
      if (Get.isLogEnable) {
        Get.log('Transcription text extracted: ${fullText.substring(0, fullText.length > 100 ? 100 : fullText.length)}...');
      }
      
      // 6. 生成会议摘要（如果需要）
      MeetingSummary? summary;
      if (generateSummary && dotenv.env['ARK_API_KEY']?.isNotEmpty == true) {
        try {
          if (Get.isLogEnable) {
            Get.log('Generating meeting summary with Doubao AI...');
          }
          
          summary = await DoubaoAIService.generateMeetingSummary(
            transcriptText: fullText,
            segments: allSegments.map((s) => TranscriptSegment(
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
      
      // 7. 清理：删除 TOS 中的音频文件（可选）
      try {
        final objectKey = audioUrl.split('/').last;
        await _storageService.deleteAudioFile(objectKey);
      } catch (e) {
        // 忽略删除错误
      }
      
      return VolcanoTranscriptionResult(
        text: fullText,
        formattedText: formattedText.isNotEmpty ? formattedText : null,
        language: 'zh-CN',
        segments: allSegments,
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
  List<VolcanoTranscriptionSegment> _convertSegments(
    List<ASRSegment>? asrSegments, {
    String? speakerIdOverride,
  }) {
    if (asrSegments == null || asrSegments.isEmpty) {
      return [];
    }
    
    if (Get.isLogEnable) {
      Get.log('Converting ${asrSegments.length} ASR segments');
    }
    
    return asrSegments.map((segment) {
      final speakerId = speakerIdOverride ?? segment.speakerId;
      
      if (Get.isLogEnable && speakerId != null) {
        Get.log('Converting segment with speaker: $speakerId');
      }
      
      return VolcanoTranscriptionSegment(
        text: segment.text,
        startTime: segment.startTime,
        endTime: segment.endTime,
        speakerId: speakerId,
        confidence: segment.confidence,
      );
    }).toList();
  }
  
  /// 格式化说话人名称
  String _formatSpeakerName(String speakerId) {
    // 检查是否是数字格式的speaker ID（如 "1", "2"）
    final numMatch = RegExp(r'^\d+$').firstMatch(speakerId);
    if (numMatch != null) {
      return '说话人 $speakerId';
    }
    
    // 检查是否是speaker_开头的格式（如 "speaker_1", "speaker_2"）
    if (speakerId.startsWith('speaker_')) {
      final num = speakerId.replaceAll('speaker_', '');
      return '说话人 $num';
    }
    
    // 检查是否是特殊类型
    switch (speakerId.toLowerCase()) {
      case 'vocal':
        return '人声';
      case 'accompaniment':
        return '伴奏';
      case 'background':
        return '背景音';
      default:
        return speakerId; // 返回原始ID
    }
  }
  
  /// 清理资源
  void dispose() {
    _storageService.dispose();
  }
}