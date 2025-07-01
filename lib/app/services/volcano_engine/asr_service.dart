import 'dart:convert';
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
      
      // 构建请求体 - 根据官方文档格式
      final requestBody = {
        'user': {
          'uid': 'flutter_meeting_app_${DateTime.now().millisecondsSinceEpoch}',
        },
        'audio': {
          'format': _getAudioFormat(audioFormat),
          'url': audioUrl,
        },
        'request': {
          'model_name': 'bigmodel',
          'enable_itn': true,  // 反向文本标准化
          'enable_punc': enablePunctuation,  // 标点符号
        },
      };
      
      // 添加可选的配置
      if (enableDiarization) {
        (requestBody['request'] as Map<String, dynamic>)['enable_speaker_separation'] = true;
      }
      if (enableTimestamp) {
        (requestBody['request'] as Map<String, dynamic>)['enable_timestamp'] = true;
      }
      
      // 发送请求 - 根据官方文档，不需要查询参数
      final url = Uri.parse('$baseUrl/submit');
      
      // Debug logging
      print('ASR Submit URL: ${url.toString()}');
      print('ASR Submit Headers: ${jsonEncode({
        'Content-Type': 'application/json',
        'X-Api-Request-Id': requestId,
        'X-Api-App-Key': appKey,
        'X-Api-Access-Key': accessKey,
        'X-Api-Resource-Id': 'volc.bigasr.auc',
      })}');
      print('ASR Submit Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Request-Id': requestId,
          'X-Api-App-Key': appKey,  // APP ID - 根据官方文档
          'X-Api-Access-Key': accessKey,  // Access Token - 根据官方文档
          'X-Api-Resource-Id': 'volc.bigasr.auc',  // 修正资源 ID
        },
        body: jsonEncode(requestBody),
      );
      
      // Debug logging: Print response details
      print('ASR Submit Response Status: ${response.statusCode}');
      print('ASR Submit Response Headers: ${response.headers}');
      print('ASR Submit Response Body: ${response.body}');
      print('Response Body Length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        // 检查API状态码 - 20000000 表示成功
        final apiStatusCode = response.headers['x-api-status-code'];
        print('API Status Code: $apiStatusCode');
        
        if (apiStatusCode == '20000000') {
          // API调用成功
          print('API call successful!');
          
          // 检查响应头中是否有任务ID
          final taskIdHeader = response.headers['x-task-id'] ?? response.headers['task-id'];
          if (taskIdHeader != null) {
            print('Task ID from header: $taskIdHeader');
            return taskIdHeader;
          }
          
          // 如果响应体为空但API状态成功，生成任务ID
          if (response.body.isEmpty || response.body == '{}') {
            print('Response body is empty but API successful - generating task ID');
            final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';
            print('Generated task ID for tracking: $taskId');
            return taskId;
          }
        }
        
        final result = jsonDecode(response.body);
        print('Parsed result: $result');
        print('Result code: ${result['code']}');
        print('Result message: ${result['message']}');
        
        if (result['code'] == 0) {
          final taskId = result['data']['task_id'];
          print('ASR task submitted successfully: $taskId');
          return taskId;
        } else {
          final errorMsg = result['message'] ?? result['header']?['message'] ?? 'Unknown error';
          throw Exception('ASR submission failed: $errorMsg (code: ${result['code']})');
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
        'task_id': taskId,
      };
      
      // 发送请求 - 根据官方文档，不需要查询参数
      final url = Uri.parse('$baseUrl/query');
      
      // Debug logging
      print('ASR Query URL: ${url.toString()}');
      print('ASR Query Headers: ${jsonEncode({
        'Content-Type': 'application/json',
        'X-Api-Request-Id': requestId,
        'X-Api-App-Key': appKey,
        'X-Api-Access-Key': accessKey,
        'X-Api-Resource-Id': 'volc.bigasr.auc',
      })}');
      print('ASR Query Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Request-Id': requestId,
          'X-Api-App-Key': appKey,  // APP ID - 根据官方文档
          'X-Api-Access-Key': accessKey,  // Access Token - 根据官方文档
          'X-Api-Resource-Id': 'volc.bigasr.auc',  // 修正资源 ID
        },
        body: jsonEncode(requestBody),
      );
      
      // Debug logging: Print response details
      print('ASR Query Response Status: ${response.statusCode}');
      print('ASR Query Response Headers: ${response.headers}');
      print('ASR Query Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        // 检查API状态码
        final apiStatusCode = response.headers['x-api-status-code'];
        print('Query API Status Code: $apiStatusCode');
        
        if (apiStatusCode == '20000000') {
          // 成功响应，但可能任务还在处理中
          if (response.body.isEmpty || response.body == '{}') {
            print('Query response empty - task might still be processing');
            return ASRTaskResult(
              taskId: taskId,
              status: 'processing',
            );
          }
        }
        
        final result = jsonDecode(response.body);
        print('Query parsed result: $result');
        
        if (result['code'] == 0) {
          return ASRTaskResult.fromJson(result['data']);
        } else {
          final errorMsg = result['message'] ?? result['header']?['message'] ?? 'Unknown query error';
          throw Exception('Query failed: $errorMsg (code: ${result['code']})');
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

  /// 将音频格式转换为火山引擎支持的格式
  String _getAudioFormat(String audioFormat) {
    switch (audioFormat.toLowerCase()) {
      case 'auto':
        return 'mp3';  // 默认使用 mp3
      case 'm4a':
        return 'mp3';  // M4A 转换为 MP3
      case 'wav':
        return 'wav';
      case 'mp3':
        return 'mp3';
      case 'ogg':
        return 'ogg';
      default:
        return 'mp3';  // 默认格式
    }
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