import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'tos_service.dart';
import 'asr_service.dart';
import 'package:get/get.dart';

/// 转录结果类
class VolcanoTranscriptionResult {
  final String text;
  final List<VolcanoTranscriptionSegment>? segments;
  final String? language;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  VolcanoTranscriptionResult({
    required this.text,
    this.segments,
    this.language,
    this.confidence,
    this.metadata,
  });
}

/// 转录片段类
class VolcanoTranscriptionSegment {
  final String text;
  final double startTime;
  final double endTime;
  final int? speakerId;
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
  late final TOSService _tosService;
  late final VolcanoASRService _asrService;
  
  VolcanoTranscriptionService() {
    // 初始化服务
    _tosService = TOSService(
      accessKeyId: dotenv.env['TOS_ACCESS_KEY_ID'] ?? '',
      secretAccessKey: dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '',
      endpoint: dotenv.env['TOS_ENDPOINT'] ?? 'tos-s3-cn-beijing.volces.com',
      bucketName: dotenv.env['TOS_BUCKET_NAME'] ?? '',
      region: dotenv.env['TOS_REGION'] ?? 'cn-beijing',
    );
    
    _asrService = VolcanoASRService(
      appKey: dotenv.env['VOLCANO_APP_KEY'] ?? '',
      accessKey: dotenv.env['VOLCANO_ACCESS_KEY'] ?? '',
    );
  }

  String get serviceName => 'Volcano Engine ASR';

  Future<bool> isAvailable() async {
    // 检查必要的配置是否存在
    return dotenv.env['VOLCANO_APP_KEY']?.isNotEmpty == true &&
           dotenv.env['VOLCANO_ACCESS_KEY']?.isNotEmpty == true &&
           dotenv.env['TOS_ACCESS_KEY_ID']?.isNotEmpty == true &&
           dotenv.env['TOS_SECRET_ACCESS_KEY']?.isNotEmpty == true &&
           dotenv.env['TOS_BUCKET_NAME']?.isNotEmpty == true;
  }

  Future<VolcanoTranscriptionResult> transcribe(File audioFile) async {
    try {
      // 1. 上传音频文件到 TOS
      if (Get.isLogEnable) {
        Get.log('Uploading audio file to TOS...');
      }
      final audioUrl = await _tosService.uploadFile(audioFile);
      if (Get.isLogEnable) {
        Get.log('Audio uploaded successfully: $audioUrl');
      }
      
      // 2. 创建 ASR 任务
      if (Get.isLogEnable) {
        Get.log('Creating ASR task...');
      }
      final taskId = await _asrService.createASRTask(
        audioUrl: audioUrl,
        language: 'zh-CN',
        enablePunctuation: true,
        enableTimestamp: true,
        audioFormat: _getAudioFormat(audioFile.path),
      );
      if (Get.isLogEnable) {
        Get.log('ASR task created: $taskId');
      }
      
      // 3. 等待并获取结果
      if (Get.isLogEnable) {
        Get.log('Waiting for ASR result...');
      }
      final asrResult = await _asrService.waitForResult(taskId);
      if (Get.isLogEnable) {
        Get.log('ASR completed successfully');
      }
      
      // 4. 转换为统一格式
      return _convertToTranscriptionResult(asrResult);
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error in Volcano transcription: $e');
      }
      rethrow;
    }
  }

  /// 从字节数据转录（需要先保存为临时文件）
  Future<VolcanoTranscriptionResult> transcribeFromBytes(Uint8List audioData, String format) async {
    // 创建临时文件
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, 'temp_audio.$format'));
    await tempFile.writeAsBytes(audioData);
    
    try {
      return await transcribe(tempFile);
    } finally {
      // 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// 获取音频格式
  String _getAudioFormat(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.mp3':
        return 'mp3';
      case '.wav':
        return 'wav';
      case '.m4a':
        return 'm4a';
      case '.aac':
        return 'aac';
      case '.pcm':
        return 'pcm';
      default:
        return 'auto';
    }
  }

  /// 转换 ASR 结果为统一格式
  VolcanoTranscriptionResult _convertToTranscriptionResult(ASRResult asrResult) {
    final segments = asrResult.segments.map((segment) {
      return VolcanoTranscriptionSegment(
        text: segment.text,
        startTime: segment.startTime,
        endTime: segment.endTime,
        speakerId: segment.speakerId,
        confidence: segment.confidence,
      );
    }).toList();
    
    return VolcanoTranscriptionResult(
      text: asrResult.text,
      segments: segments,
      language: asrResult.language,
      confidence: asrResult.confidence,
      metadata: {
        'provider': 'volcano',
        'segments_count': segments.length,
      },
    );
  }
}