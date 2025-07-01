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
        (requestBody['request'] as Map<String, dynamic>)['enable_speaker_info'] = true;
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
          
          // 检查响应头中的任务标识 - 尝试多个可能的字段
          final requestId = response.headers['x-api-request-id'];
          final logId = response.headers['x-tt-logid'];
          final traceId = response.headers['x-tt-trace-id'];
          
          print('Available IDs:');
          print('  x-api-request-id: $requestId');
          print('  x-tt-logid: $logId');
          print('  x-tt-trace-id: $traceId');
          
          // 优先使用 x-api-request-id 作为任务ID
          if (requestId != null && requestId.isNotEmpty) {
            print('Using x-api-request-id as task ID: $requestId');
            return requestId;
          }
          
          // 备选：使用 x-tt-logid
          if (logId != null && logId.isNotEmpty) {
            print('Using x-tt-logid as task ID: $logId');
            return logId;
          }
          
          // 最后备选：使用 x-tt-trace-id 的一部分
          if (traceId != null && traceId.isNotEmpty) {
            print('Using x-tt-trace-id as task ID: $traceId');
            return traceId.split('-')[1]; // 使用trace ID的第二部分
          }
          
          // 如果都没有，仍然生成一个任务ID
          if (response.body.isEmpty || response.body == '{}') {
            print('No task ID found in headers, generating fallback ID');
            final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';
            print('Generated fallback task ID: $taskId');
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
      // 根据文档，查询时任务ID应该在 X-Api-Request-Id 头中
      // 请求体应该是空的 JSON 对象
      final requestBody = <String, dynamic>{};
      
      // 发送请求 - 根据官方文档，任务ID在请求头中
      final url = Uri.parse('$baseUrl/query');
      
      // Debug logging
      print('ASR Query URL: ${url.toString()}');
      print('ASR Query Headers: ${jsonEncode({
        'Content-Type': 'application/json',
        'X-Api-Request-Id': taskId,  // 使用任务ID作为请求ID
        'X-Api-App-Key': appKey,
        'X-Api-Access-Key': accessKey,
        'X-Api-Resource-Id': 'volc.bigasr.auc',
      })}');
      print('ASR Query Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Request-Id': taskId,  // 任务ID在这里 - 根据官方文档
          'X-Api-App-Key': appKey,  // APP ID
          'X-Api-Access-Key': accessKey,  // Access Token
          'X-Api-Resource-Id': 'volc.bigasr.auc',  // 资源 ID
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
        final apiMessage = response.headers['x-api-message'];
        print('Query API Status Code: $apiStatusCode');
        print('Query API Message: $apiMessage');
        
        if (apiStatusCode == '20000000') {
          // 成功响应
          if (response.body.isEmpty || response.body == '{}') {
            print('Query response empty - task completed successfully');
            return ASRTaskResult(
              taskId: taskId,
              status: 'success',
            );
          }
          
          // 解析火山引擎的成功响应体
          try {
            final result = jsonDecode(response.body);
            print('Query parsed result: $result');
            
            // 火山引擎成功响应不包含 'code' 字段，直接解析结果
            if (result.containsKey('result') && result['result'] != null) {
              print('ASR transcription completed successfully');
              return ASRTaskResult.fromVolcanoResponse(taskId, result);
            } else {
              // 如果没有result字段，可能是任务还在处理但状态是成功
              return ASRTaskResult(
                taskId: taskId,
                status: 'success',
              );
            }
          } catch (e) {
            print('Failed to parse success response: $e');
            // 如果解析失败，但API状态码是成功的，返回成功状态
            return ASRTaskResult(
              taskId: taskId,
              status: 'success',
            );
          }
        } else if (apiStatusCode == '20000001') {
          // 任务正在处理中
          return ASRTaskResult(
            taskId: taskId,
            status: 'processing',
          );
        } else if (apiStatusCode == '20000002') {
          // 任务在队列中
          return ASRTaskResult(
            taskId: taskId,
            status: 'queued',
          );
        } else {
          // 处理各种错误状态码
          final errorMsg = _getErrorMessage(apiStatusCode, apiMessage);
          throw Exception('ASR task failed: $errorMsg (code: $apiStatusCode)');
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

  /// 根据错误状态码返回友好的错误消息
  String _getErrorMessage(String? statusCode, String? apiMessage) {
    // 首先尝试从API消息中提取有用信息
    if (apiMessage != null && apiMessage.isNotEmpty) {
      if (apiMessage.contains('Invalid audio format') || apiMessage.contains('audio convert failed')) {
        return '音频格式无效，请使用MP3、WAV或M4A格式的音频文件';
      }
      if (apiMessage.contains('cannot find task')) {
        return '找不到指定的任务，任务可能已过期或不存在';
      }
      if (apiMessage.contains('Process failed')) {
        return '音频处理失败：$apiMessage';
      }
    }

    // 根据状态码返回对应的错误消息
    switch (statusCode) {
      case '45000000':
        return '请求参数错误';
      case '45000001':
        return '无效的参数';
      case '45000151':
        return '音频格式无效，请使用MP3、WAV或M4A格式的音频文件';
      case '45000152':
        return '音频文件过大，请使用小于500MB的音频文件';
      case '45000153':
        return '音频时长过长，请使用短于5小时的音频文件';
      case '50000000':
        return '服务器内部错误，请稍后重试';
      case '55000000':
        return '服务暂时不可用，请稍后重试';
      default:
        if (apiMessage != null && apiMessage.isNotEmpty) {
          return apiMessage;
        }
        return '未知错误 (状态码: $statusCode)';
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

  /// 从火山引擎API响应创建ASRTaskResult
  factory ASRTaskResult.fromVolcanoResponse(String taskId, Map<String, dynamic> volcanoResponse) {
    List<ASRSegment>? segments;
    String? transcriptText;
    Map<String, dynamic>? metadata;
    
    // 解析火山引擎的响应格式
    if (volcanoResponse['result'] != null) {
      final result = volcanoResponse['result'];
      
      // 提取转录文本 - 检查text字段是否存在
      if (result.containsKey('text') && result['text'] != null) {
        transcriptText = result['text'] as String?;
      }
      
      // 解析utterances为segments
      if (result['utterances'] is List && (result['utterances'] as List).isNotEmpty) {
        segments = (result['utterances'] as List)
            .map((utterance) => ASRSegment.fromVolcanoUtterance(utterance))
            .toList();
        
        // 如果没有直接的text字段，从utterances中拼接文本
        if (transcriptText == null || transcriptText.isEmpty) {
          transcriptText = segments.map((s) => s.text).join(' ');
        }
      }
      
      // 保存额外信息
      metadata = {
        'duration': volcanoResponse['audio_info']?['duration'],
        'additions': result['additions'],
      };
    }
    
    return ASRTaskResult(
      taskId: taskId,
      status: 'success',
      transcriptUrl: null,
      errorMessage: null,
      segments: segments,
      metadata: {
        'transcript_text': transcriptText ?? '',
        'volcano_response': metadata,
      },
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

  /// 从火山引擎的utterance格式创建ASRSegment
  factory ASRSegment.fromVolcanoUtterance(Map<String, dynamic> utterance) {
    List<ASRWord>? words;
    if (utterance['words'] is List) {
      words = (utterance['words'] as List)
          .map((w) => ASRWord.fromVolcanoWord(w))
          .toList();
    }
    
    // Debug logging
    if (Get.isLogEnable) {
      Get.log('Parsing utterance: $utterance');
    }
    final text = utterance['text'] ?? '';
    if (Get.isLogEnable) {
      Get.log('Extracted text: $text');
    }
    
    // 提取说话人ID - 火山引擎返回的speaker_id字段
    String? speakerId;
    if (utterance.containsKey('speaker_id')) {
      speakerId = utterance['speaker_id']?.toString();
    }
    
    return ASRSegment(
      text: text,
      startTime: (utterance['start_time'] as num?)?.toDouble() ?? 0.0,
      endTime: (utterance['end_time'] as num?)?.toDouble() ?? 0.0,
      speakerId: speakerId,
      confidence: (utterance['confidence'] as num?)?.toDouble(),
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

  /// 从火山引擎的word格式创建ASRWord
  factory ASRWord.fromVolcanoWord(Map<String, dynamic> word) {
    return ASRWord(
      word: word['text'] ?? '', // 火山引擎使用 'text' 而不是 'word'
      startTime: (word['start_time'] as num?)?.toDouble() ?? 0.0,
      endTime: (word['end_time'] as num?)?.toDouble() ?? 0.0,
      confidence: (word['confidence'] as num?)?.toDouble(),
    );
  }
}