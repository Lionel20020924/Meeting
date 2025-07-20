import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

/// 火山引擎声音分离服务
/// 用于将混合音频分离成多个独立的音轨（如人声、背景音、不同说话人等）
class VoiceSeparationService {
  final String appKey;
  final String accessKey;
  static const String baseUrl = 'https://openspeech.bytedance.com/api/v3/sauc/v1';
  
  VoiceSeparationService({
    required this.appKey,
    required this.accessKey,
  });

  /// 提交声音分离任务
  Future<String> submitSeparationTask({
    required String audioUrl,
    String separationType = 'speaker', // speaker: 说话人分离, vocal: 人声伴奏分离
    int? maxSpeakers, // 最大说话人数量，仅在speaker模式下有效
    bool enableDenoising = true, // 是否启用降噪
    String audioFormat = 'auto',
  }) async {
    try {
      final requestId = const Uuid().v4();
      
      // 构建请求体
      final requestBody = {
        'user': {
          'uid': 'flutter_meeting_app_${DateTime.now().millisecondsSinceEpoch}',
        },
        'audio': {
          'format': _getAudioFormat(audioFormat),
          'url': audioUrl,
        },
        'request': {
          'separation_type': separationType,
          'enable_denoising': enableDenoising,
        },
      };
      
      // 添加可选参数
      if (separationType == 'speaker' && maxSpeakers != null) {
        (requestBody['request'] as Map<String, dynamic>)['max_speakers'] = maxSpeakers;
      }
      
      // 发送请求
      final url = Uri.parse('$baseUrl/submit');
      
      if (Get.isLogEnable) {
        Get.log('=== Voice Separation Task Submission ===');
        Get.log('URL: ${url.toString()}');
        Get.log('Audio URL: $audioUrl');
        Get.log('Separation Type: $separationType');
        Get.log('Max Speakers: ${maxSpeakers ?? "auto"}');
        Get.log('Enable Denoising: $enableDenoising');
        Get.log('Request ID: $requestId');
        Get.log('Request Body: ${const JsonEncoder.withIndent('  ').convert(requestBody)}');
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Request-Id': requestId,
          'X-Api-App-Key': appKey,
          'X-Api-Access-Key': accessKey,
          'X-Api-Resource-Id': 'volc.sauc.separation',
        },
        body: jsonEncode(requestBody),
      );
      
      if (Get.isLogEnable) {
        Get.log('=== Voice Separation Response ===');
        Get.log('Status Code: ${response.statusCode}');
        Get.log('Headers:');
        response.headers.forEach((key, value) {
          Get.log('  $key: $value');
        });
        Get.log('Response Body: ${response.body}');
        
        // Try to parse and pretty print JSON response
        try {
          if (response.body.isNotEmpty) {
            final jsonResponse = jsonDecode(response.body);
            Get.log('Parsed Response: ${const JsonEncoder.withIndent('  ').convert(jsonResponse)}');
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }
      
      if (response.statusCode == 200) {
        // 检查API状态码
        final apiStatusCode = response.headers['x-api-status-code'];
        
        if (apiStatusCode == '20000000') {
          // 成功提交
          final requestId = response.headers['x-api-request-id'];
          if (requestId != null && requestId.isNotEmpty) {
            if (Get.isLogEnable) {
              Get.log('Voice separation task submitted successfully: $requestId');
            }
            return requestId;
          }
          
          // 如果响应体包含task_id
          if (response.body.isNotEmpty && response.body != '{}') {
            final result = jsonDecode(response.body);
            if (result['code'] == 0 && result['data'] != null) {
              final taskId = result['data']['task_id'];
              return taskId;
            }
          }
          
          throw Exception('No task ID returned from voice separation API');
        } else {
          final errorMsg = _getErrorMessage(apiStatusCode, response.headers['x-api-message']);
          throw Exception('Voice separation submission failed: $errorMsg');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error submitting voice separation task: $e');
      }
      rethrow;
    }
  }

  /// 查询分离任务状态
  Future<VoiceSeparationResult> queryTaskStatus(String taskId) async {
    try {
      final url = Uri.parse('$baseUrl/query');
      
      if (Get.isLogEnable) {
        Get.log('=== Voice Separation Status Query ===');
        Get.log('Task ID: $taskId');
        Get.log('URL: ${url.toString()}');
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Request-Id': taskId,
          'X-Api-App-Key': appKey,
          'X-Api-Access-Key': accessKey,
          'X-Api-Resource-Id': 'volc.sauc.separation',
        },
        body: jsonEncode({}),
      );
      
      if (Get.isLogEnable) {
        Get.log('=== Voice Separation Query Response ===');
        Get.log('Status Code: ${response.statusCode}');
        Get.log('Headers:');
        response.headers.forEach((key, value) {
          Get.log('  $key: $value');
        });
        Get.log('Response Body: ${response.body}');
        
        // Try to parse and pretty print JSON response
        try {
          if (response.body.isNotEmpty) {
            final jsonResponse = jsonDecode(response.body);
            Get.log('Parsed Response: ${const JsonEncoder.withIndent('  ').convert(jsonResponse)}');
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }
      
      if (response.statusCode == 200) {
        final apiStatusCode = response.headers['x-api-status-code'];
        
        if (apiStatusCode == '20000000') {
          // 任务完成
          if (response.body.isEmpty || response.body == '{}') {
            return VoiceSeparationResult(
              taskId: taskId,
              status: 'success',
              tracks: [],
            );
          }
          
          final result = jsonDecode(response.body);
          return VoiceSeparationResult.fromVolcanoResponse(taskId, result);
        } else if (apiStatusCode == '20000001') {
          // 任务处理中
          return VoiceSeparationResult(
            taskId: taskId,
            status: 'processing',
          );
        } else if (apiStatusCode == '20000002') {
          // 任务在队列中
          return VoiceSeparationResult(
            taskId: taskId,
            status: 'queued',
          );
        } else {
          final errorMsg = _getErrorMessage(apiStatusCode, response.headers['x-api-message']);
          throw Exception('Voice separation task failed: $errorMsg');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error querying voice separation task: $e');
      }
      rethrow;
    }
  }

  /// 等待任务完成并返回结果
  Future<VoiceSeparationResult> waitForResult(String taskId, {Duration? timeout}) async {
    final endTime = timeout != null ? DateTime.now().add(timeout) : null;
    final startTime = DateTime.now();
    int queryCount = 0;
    
    if (Get.isLogEnable) {
      Get.log('=== Voice Separation Waiting for Result ===');
      Get.log('Task ID: $taskId');
      Get.log('Timeout: ${timeout?.inSeconds ?? "unlimited"} seconds');
    }
    
    while (true) {
      queryCount++;
      
      if (endTime != null && DateTime.now().isAfter(endTime)) {
        final elapsed = DateTime.now().difference(startTime);
        if (Get.isLogEnable) {
          Get.log('Voice separation task timed out after ${elapsed.inSeconds} seconds and $queryCount queries');
        }
        throw Exception('Voice separation task timed out');
      }
      
      final status = await queryTaskStatus(taskId);
      
      if (status.status == 'success') {
        final elapsed = DateTime.now().difference(startTime);
        if (Get.isLogEnable) {
          Get.log('=== Voice Separation Completed ===');
          Get.log('Total time: ${elapsed.inSeconds} seconds');
          Get.log('Total queries: $queryCount');
          Get.log('Number of tracks: ${status.tracks?.length ?? 0}');
          
          status.tracks?.forEach((track) {
            Get.log('Track: ${track.friendlyName} (${track.trackType})');
            Get.log('  URL: ${track.downloadUrl}');
          });
        }
        return status;
      } else if (status.status == 'failed') {
        if (Get.isLogEnable) {
          Get.log('Voice separation task failed: ${status.errorMessage}');
        }
        throw Exception('Voice separation task failed: ${status.errorMessage}');
      }
      
      if (Get.isLogEnable) {
        final elapsed = DateTime.now().difference(startTime);
        Get.log('Still processing... (${elapsed.inSeconds}s elapsed, query #$queryCount, status: ${status.status})');
      }
      
      // 等待3秒后重试
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// 将音频格式转换为火山引擎支持的格式
  String _getAudioFormat(String audioFormat) {
    switch (audioFormat.toLowerCase()) {
      case 'auto':
        return 'mp3';
      case 'm4a':
        return 'mp3';
      case 'wav':
        return 'wav';
      case 'mp3':
        return 'mp3';
      case 'ogg':
        return 'ogg';
      default:
        return 'mp3';
    }
  }

  /// 根据错误状态码返回友好的错误消息
  String _getErrorMessage(String? statusCode, String? apiMessage) {
    if (apiMessage != null && apiMessage.isNotEmpty) {
      return apiMessage;
    }

    // Enhanced error messages with troubleshooting hints
    switch (statusCode) {
      case '45000000':
        return '请求参数错误 - 请检查音频URL和格式是否正确';
      case '45000001':
        return '无效的参数 - 请确保所有必需参数都已提供';
      case '45000151':
        return '音频格式无效 - 支持格式：WAV, MP3, M4A, FLAC';
      case '45000152':
        return '音频文件过大 - 最大支持200MB';
      case '45000153':
        return '音频时长过长 - 最大支持3小时';
      case '50000000':
        return '服务器内部错误 - 请稍后重试';
      case '55000000':
        return '服务暂时不可用 - 请稍后重试';
      case '40000001':
        return '认证失败 - 请检查.env文件中的API密钥配置';
      case '40000002':
        return '权限不足 - 请确认您的API账户有声音分离权限';
      case '30000001':
        return '未检测到语音 - 音频中可能没有人声';
      case '30000002':
        return '无法分离说话人 - 音频可能只有一个说话人或音质较差';
      default:
        return '未知错误 (状态码: $statusCode) - 请查看日志获取详细信息';
    }
  }
}

/// 声音分离任务结果
class VoiceSeparationResult {
  final String taskId;
  final String status; // queued, processing, success, failed
  final List<SeparatedTrack>? tracks;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  VoiceSeparationResult({
    required this.taskId,
    required this.status,
    this.tracks,
    this.errorMessage,
    this.metadata,
  });

  /// 从火山引擎API响应创建结果
  factory VoiceSeparationResult.fromVolcanoResponse(String taskId, Map<String, dynamic> response) {
    List<SeparatedTrack>? tracks;
    
    if (response['result'] != null && response['result']['tracks'] is List) {
      tracks = (response['result']['tracks'] as List)
          .map((track) => SeparatedTrack.fromJson(track))
          .toList();
    }
    
    return VoiceSeparationResult(
      taskId: taskId,
      status: 'success',
      tracks: tracks,
      metadata: response['audio_info'],
    );
  }
}

/// 分离后的音轨信息
class SeparatedTrack {
  final String trackId;
  final String trackType; // vocal, accompaniment, speaker_1, speaker_2, etc.
  final String downloadUrl;
  final double? duration;
  final Map<String, dynamic>? metadata;

  SeparatedTrack({
    required this.trackId,
    required this.trackType,
    required this.downloadUrl,
    this.duration,
    this.metadata,
  });

  factory SeparatedTrack.fromJson(Map<String, dynamic> json) {
    return SeparatedTrack(
      trackId: json['track_id'] ?? '',
      trackType: json['track_type'] ?? 'unknown',
      downloadUrl: json['download_url'] ?? '',
      duration: (json['duration'] as num?)?.toDouble(),
      metadata: json['metadata'],
    );
  }

  /// 获取友好的音轨名称
  String get friendlyName {
    switch (trackType) {
      case 'vocal':
        return '人声';
      case 'accompaniment':
        return '伴奏';
      case 'background':
        return '背景音';
      default:
        if (trackType.startsWith('speaker_')) {
          final speakerNum = trackType.replaceAll('speaker_', '');
          return '说话人 $speakerNum';
        }
        return trackType;
    }
  }
}