import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

/// 火山引擎语音识别服务 - 大模型版本
class VolcanoASRService {
  final String appKey;
  final String accessKey;
  static const String baseUrl = 'https://openspeech.bytedance.com/api/v3/auc/bigmodel';
  
  VolcanoASRService({
    required this.appKey,
    required this.accessKey,
  });

  /// 提交语音识别任务
  Future<String> submitASRTask({
    required String audioUrl,
    String language = 'zh-CN',
    bool enableDiarization = true,
    bool enableIntelligentSegment = true,
    bool enablePunctuation = true,
    bool enableTimestamp = true,
    String audioFormat = 'auto',
  }) async {
    try {
      final requestId = const Uuid().v4();
      
      // 构建请求体
      final requestBody = {
        'app': {
          'appid': appKey,
          'cluster': 'volc_bigasr_default',  // 添加集群配置
        },
        'user': {
          'uid': 'flutter_meeting_app_${DateTime.now().millisecondsSinceEpoch}',
        },
        'request': {
          'audio_url': audioUrl,
          'language': language,
          'enable_diarization': enableDiarization,
          'enable_intelligent_segment': enableIntelligentSegment,
          'enable_punctuation': enablePunctuation,
          'enable_timestamp': enableTimestamp,
          'audio_format': audioFormat,
          'request_id': requestId,
          'resource_id': 'volc.bigasr.auc.v3',  // 添加资源 ID
        },
      };
      
      // 生成签名
      final signature = _generateSignature(requestBody);
      
      // 发送请求 - 尝试使用 appid 作为查询参数
      final url = Uri.parse('$baseUrl/submit').replace(queryParameters: {
        'appid': appKey,  // Try 'appid' as the parameter name
      });
      
      // Debug logging
      if (Get.isLogEnable) {
        Get.log('ASR Submit URL: ${url.toString()}');
        Get.log('ASR Submit Headers: ${jsonEncode({
          'Content-Type': 'application/json',
          'X-Api-Request-Id': requestId,
          'X-Api-Resource-Id': 'volc.bigasr.auc.v3',
          'X-Signature': signature,
        })}');
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Request-Id': requestId,
          'X-Api-Resource-Id': 'volc.bigasr.auc.v3',
          'X-Signature': signature,
        },
        body: jsonEncode(requestBody),
      );
      
      // Debug logging: Print response details
      if (Get.isLogEnable) {
        Get.log('ASR Submit Response Status: ${response.statusCode}');
        Get.log('ASR Submit Response Body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['code'] == 0) {
          final taskId = result['data']['task_id'];
          if (Get.isLogEnable) {
            Get.log('ASR task submitted successfully: $taskId');
          }
          return taskId;
        } else {
          throw Exception('ASR submission failed: ${result['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error submitting ASR task: $e');
      }
      rethrow;
    }
  }

  /// 查询识别任务状态
  Future<ASRTaskResult> queryTaskStatus(String taskId) async {
    try {
      final requestId = const Uuid().v4();
      
      final requestBody = {
        'app': {
          'appid': appKey,
        },
        'request': {
          'task_id': taskId,
          'request_id': requestId,
        },
      };
      
      final signature = _generateSignature(requestBody);
      
      // 发送请求 - 使用 appid 作为查询参数
      final url = Uri.parse('$baseUrl/query').replace(queryParameters: {
        'appid': appKey,
      });
      
      // Debug logging: Print full URL with query parameters
      if (Get.isLogEnable) {
        Get.log('ASR Query URL: ${url.toString()}');
        Get.log('ASR Query Headers: ${jsonEncode({
          'Content-Type': 'application/json',
          'X-Api-Request-Id': requestId,
          'X-Api-Key': appKey,
          'X-Api-Access-Key': accessKey,
          'X-Signature': signature,
        })}');
        Get.log('ASR Query Body: ${jsonEncode(requestBody)}');
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Request-Id': requestId,
          'X-Api-Resource-Id': 'volc.bigasr.auc.v3',
          'X-Signature': signature,
        },
        body: jsonEncode(requestBody),
      );
      
      // Debug logging: Print response details
      if (Get.isLogEnable) {
        Get.log('ASR Query Response Status: ${response.statusCode}');
        Get.log('ASR Query Response Body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['code'] == 0) {
          return ASRTaskResult.fromJson(result['data']);
        } else {
          throw Exception('Query failed: ${result['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error querying ASR task: $e');
      }
      rethrow;
    }
  }

  /// 等待任务完成并返回结果
  Future<ASRTaskResult> waitForResult(String taskId, {Duration? timeout}) async {
    final endTime = timeout != null ? DateTime.now().add(timeout) : null;
    
    while (true) {
      // 检查超时
      if (endTime != null && DateTime.now().isAfter(endTime)) {
        throw Exception('ASR task timed out');
      }
      
      final status = await queryTaskStatus(taskId);
      
      if (status.status == 'success') {
        if (Get.isLogEnable) {
          Get.log('ASR task completed successfully');
        }
        return status;
      } else if (status.status == 'failed') {
        throw Exception('ASR task failed: ${status.errorMessage}');
      }
      
      // 等待 3 秒后重试
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// 生成签名
  String _generateSignature(Map<String, dynamic> requestBody) {
    // 将请求体转换为规范字符串
    final canonicalString = _buildCanonicalString(requestBody);
    
    // 使用 HMAC-SHA256 生成签名
    final key = utf8.encode(accessKey);
    final bytes = utf8.encode(canonicalString);
    
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    
    return base64.encode(digest.bytes);
  }

  /// 构建规范字符串
  String _buildCanonicalString(Map<String, dynamic> data) {
    // 火山引擎要求的签名规则可能有所不同
    // 这里使用简单的 JSON 字符串作为签名源
    final jsonString = jsonEncode(data);
    return jsonString;
  }
}

/// ASR 任务状态
class ASRTaskResult {
  final String taskId;
  final String status; // processing, success, failed
  final String? transcriptUrl;
  final String? errorMessage;
  final List<ASRSegment>? segments;
  final Map<String, dynamic>? metadata;

  ASRTaskResult({
    required this.taskId,
    required this.status,
    this.transcriptUrl,
    this.errorMessage,
    this.segments,
    this.metadata,
  });

  factory ASRTaskResult.fromJson(Map<String, dynamic> json) {
    List<ASRSegment>? segments;
    
    // 如果任务完成，解析转录结果
    if (json['status'] == 'success' && json['result'] != null) {
      final result = json['result'];
      if (result['segments'] is List) {
        segments = (result['segments'] as List)
            .map((s) => ASRSegment.fromJson(s))
            .toList();
      }
    }
    
    return ASRTaskResult(
      taskId: json['task_id'] ?? '',
      status: json['status'] ?? 'unknown',
      transcriptUrl: json['transcript_url'],
      errorMessage: json['error_message'],
      segments: segments,
      metadata: json['metadata'],
    );
  }
}

/// ASR 分段结果
class ASRSegment {
  final String text;
  final double startTime;
  final double endTime;
  final String? speakerId;
  final double? confidence;
  final List<ASRWord>? words;

  ASRSegment({
    required this.text,
    required this.startTime,
    required this.endTime,
    this.speakerId,
    this.confidence,
    this.words,
  });

  factory ASRSegment.fromJson(Map<String, dynamic> json) {
    List<ASRWord>? words;
    if (json['words'] is List) {
      words = (json['words'] as List)
          .map((w) => ASRWord.fromJson(w))
          .toList();
    }
    
    return ASRSegment(
      text: json['text'] ?? '',
      startTime: (json['start_time'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['end_time'] as num?)?.toDouble() ?? 0.0,
      speakerId: json['speaker_id'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      words: words,
    );
  }
}

/// ASR 词级别结果
class ASRWord {
  final String word;
  final double startTime;
  final double endTime;
  final double? confidence;

  ASRWord({
    required this.word,
    required this.startTime,
    required this.endTime,
    this.confidence,
  });

  factory ASRWord.fromJson(Map<String, dynamic> json) {
    return ASRWord(
      word: json['word'] ?? '',
      startTime: (json['start_time'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['end_time'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}