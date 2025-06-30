import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

/// 火山引擎语音识别服务
class VolcanoASRService {
  final String appKey;
  final String accessKey;
  static const String baseUrl = 'https://openspeech.bytedance.com/api/v1/asr';
  
  VolcanoASRService({
    required this.appKey,
    required this.accessKey,
  });

  /// 创建语音识别任务
  Future<String> createASRTask({
    required String audioUrl,
    String language = 'zh-CN',
    bool enablePunctuation = true,
    bool enableTimestamp = true,
    bool enableDiarization = false,
    String audioFormat = 'auto',
  }) async {
    try {
      final requestId = const Uuid().v4();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 构建请求体
      final requestBody = {
        'app': {
          'appid': appKey,
          'token': _generateToken(timestamp),
          'cluster': 'volcano_asr',
        },
        'user': {
          'uid': 'flutter_meeting_app',
        },
        'audio': {
          'url': audioUrl,
          'format': audioFormat,
          'language': language,
        },
        'config': {
          'enable_punctuation': enablePunctuation,
          'enable_timestamp': enableTimestamp,
          'enable_diarization': enableDiarization,
          'max_lines': 1000,
        },
      };
      
      // 生成签名
      final signature = _generateSignature(
        requestBody: requestBody,
        timestamp: timestamp,
      );
      
      // 发送请求
      final response = await http.post(
        Uri.parse('$baseUrl/submit'),
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': requestId,
          'X-Timestamp': timestamp,
          'X-Signature': signature,
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['code'] == 0) {
          return result['data']['task_id'];
        } else {
          throw Exception('ASR task creation failed: ${result['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error creating ASR task: $e');
      }
      rethrow;
    }
  }

  /// 查询识别任务状态
  Future<ASRTaskStatus> queryTaskStatus(String taskId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      final requestBody = {
        'app': {
          'appid': appKey,
          'token': _generateToken(timestamp),
          'cluster': 'volcano_asr',
        },
        'task_id': taskId,
      };
      
      final signature = _generateSignature(
        requestBody: requestBody,
        timestamp: timestamp,
      );
      
      final response = await http.post(
        Uri.parse('$baseUrl/query'),
        headers: {
          'Content-Type': 'application/json',
          'X-Timestamp': timestamp,
          'X-Signature': signature,
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['code'] == 0) {
          return ASRTaskStatus.fromJson(result['data']);
        } else {
          throw Exception('Query failed: ${result['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error querying ASR task: $e');
      }
      rethrow;
    }
  }

  /// 等待任务完成并获取结果
  Future<ASRResult> waitForResult(String taskId, {
    Duration timeout = const Duration(minutes: 30),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final status = await queryTaskStatus(taskId);
      
      switch (status.status) {
        case 'completed':
          return status.result!;
        case 'failed':
          throw Exception('ASR task failed: ${status.errorMessage}');
        case 'processing':
        case 'pending':
          await Future.delayed(pollInterval);
          break;
        default:
          throw Exception('Unknown task status: ${status.status}');
      }
    }
    
    throw Exception('ASR task timeout after ${timeout.inMinutes} minutes');
  }

  /// 生成访问令牌
  String _generateToken(String timestamp) {
    final data = '$appKey$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 生成请求签名
  String _generateSignature({
    required Map<String, dynamic> requestBody,
    required String timestamp,
  }) {
    final sortedBody = _sortJsonKeys(requestBody);
    final bodyStr = jsonEncode(sortedBody);
    final signStr = '$accessKey$timestamp$bodyStr';
    
    final bytes = utf8.encode(signStr);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 递归排序JSON键
  dynamic _sortJsonKeys(dynamic obj) {
    if (obj is Map) {
      final sorted = <String, dynamic>{};
      final keys = obj.keys.toList()..sort();
      for (final key in keys) {
        sorted[key] = _sortJsonKeys(obj[key]);
      }
      return sorted;
    } else if (obj is List) {
      return obj.map(_sortJsonKeys).toList();
    } else {
      return obj;
    }
  }
}

/// ASR任务状态
class ASRTaskStatus {
  final String taskId;
  final String status; // pending, processing, completed, failed
  final double? progress;
  final String? errorMessage;
  final ASRResult? result;

  ASRTaskStatus({
    required this.taskId,
    required this.status,
    this.progress,
    this.errorMessage,
    this.result,
  });

  factory ASRTaskStatus.fromJson(Map<String, dynamic> json) {
    return ASRTaskStatus(
      taskId: json['task_id'],
      status: json['status'],
      progress: json['progress']?.toDouble(),
      errorMessage: json['error_message'],
      result: json['result'] != null ? ASRResult.fromJson(json['result']) : null,
    );
  }
}

/// ASR识别结果
class ASRResult {
  final String text;
  final List<ASRSegment> segments;
  final double? confidence;
  final String? language;

  ASRResult({
    required this.text,
    required this.segments,
    this.confidence,
    this.language,
  });

  factory ASRResult.fromJson(Map<String, dynamic> json) {
    return ASRResult(
      text: json['text'] ?? '',
      segments: (json['segments'] as List?)
          ?.map((s) => ASRSegment.fromJson(s))
          .toList() ?? [],
      confidence: json['confidence']?.toDouble(),
      language: json['language'],
    );
  }
}

/// ASR片段（带时间戳）
class ASRSegment {
  final String text;
  final double startTime;
  final double endTime;
  final double? confidence;
  final int? speakerId;

  ASRSegment({
    required this.text,
    required this.startTime,
    required this.endTime,
    this.confidence,
    this.speakerId,
  });

  factory ASRSegment.fromJson(Map<String, dynamic> json) {
    return ASRSegment(
      text: json['text'],
      startTime: json['start_time'].toDouble(),
      endTime: json['end_time'].toDouble(),
      confidence: json['confidence']?.toDouble(),
      speakerId: json['speaker_id'],
    );
  }
}