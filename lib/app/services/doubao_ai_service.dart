import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// 豆包 AI 服务 - 用于生成会议摘要
class DoubaoAIService {
  static const String baseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
  static String get apiKey => dotenv.env['ARK_API_KEY'] ?? '';
  
  /// 生成会议摘要
  static Future<MeetingSummary> generateMeetingSummary({
    required String transcriptText,
    List<TranscriptSegment>? segments,
    String? meetingTitle,
    DateTime? meetingDate,
  }) async {
    try {
      if (apiKey.isEmpty) {
        throw Exception('豆包 AI API key 未配置');
      }
      
      // 构建提示词
      final prompt = _buildSummaryPrompt(
        transcriptText: transcriptText,
        segments: segments,
        meetingTitle: meetingTitle,
        meetingDate: meetingDate,
      );
      
      // 调用豆包 AI API
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'ep-20241229145808-bjc6f', // 豆包通用模型
          'messages': [
            {
              'role': 'system',
              'content': '你是一个专业的会议助手，擅长分析会议内容并生成结构化的会议纪要。',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.1, // 降低温度以获得更稳定的输出
          'max_tokens': 2048,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final content = result['choices'][0]['message']['content'];
        
        if (Get.isLogEnable) {
          Get.log('会议摘要生成成功');
        }
        
        return _parseSummaryContent(content);
      } else {
        throw Exception('豆包 AI 请求失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('生成会议摘要失败: $e');
      }
      rethrow;
    }
  }
  
  /// 构建摘要生成提示词
  static String _buildSummaryPrompt({
    required String transcriptText,
    List<TranscriptSegment>? segments,
    String? meetingTitle,
    DateTime? meetingDate,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('请根据以下会议记录生成详细的会议纪要：\n');
    
    if (meetingTitle != null) {
      buffer.writeln('会议主题：$meetingTitle');
    }
    
    if (meetingDate != null) {
      buffer.writeln('会议时间：${meetingDate.toString().split('.')[0]}');
    }
    
    if (segments != null && segments.isNotEmpty) {
      // 如果有说话人信息，按说话人分组
      final speakerGroups = <String, List<String>>{};
      for (final segment in segments) {
        final speaker = segment.speakerId ?? '未知发言人';
        speakerGroups.putIfAbsent(speaker, () => []).add(segment.text);
      }
      
      buffer.writeln('\n发言记录：');
      for (final entry in speakerGroups.entries) {
        buffer.writeln('\n${entry.key}的发言：');
        for (final text in entry.value) {
          buffer.writeln('- $text');
        }
      }
    } else {
      buffer.writeln('\n会议内容：');
      buffer.writeln(transcriptText);
    }
    
    buffer.writeln('\n请生成包含以下内容的会议纪要：');
    buffer.writeln('1. 会议概要（50字以内）');
    buffer.writeln('2. 主要议题（列出3-5个要点）');
    buffer.writeln('3. 关键决策（如果有）');
    buffer.writeln('4. 行动项（包括负责人和截止时间，如果提到）');
    buffer.writeln('5. 下一步计划');
    buffer.writeln('\n请使用结构化的 JSON 格式返回结果。');
    
    return buffer.toString();
  }
  
  /// 解析 AI 返回的摘要内容
  static MeetingSummary _parseSummaryContent(String content) {
    try {
      // 尝试解析 JSON 格式
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        return MeetingSummary.fromJson(json);
      }
    } catch (e) {
      // JSON 解析失败，使用备用解析方法
    }
    
    // 备用解析：从纯文本中提取信息
    return MeetingSummary(
      summary: _extractSection(content, '会议概要', '概要'),
      keyPoints: _extractListSection(content, '主要议题', '议题'),
      decisions: _extractListSection(content, '关键决策', '决策'),
      actionItems: _extractActionItems(content),
      nextSteps: _extractSection(content, '下一步计划', '计划'),
      rawContent: content,
    );
  }
  
  /// 提取文本段落
  static String _extractSection(String content, String primary, String fallback) {
    final patterns = [
      RegExp('$primary[：:]\\s*([^\\n]+)', multiLine: true),
      RegExp('$fallback[：:]\\s*([^\\n]+)', multiLine: true),
      RegExp('\\d+\\.\\s*$primary[：:]\\s*([^\\n]+)', multiLine: true),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    
    return '';
  }
  
  /// 提取列表项
  static List<String> _extractListSection(String content, String primary, String fallback) {
    final section = _extractSection(content, primary, fallback);
    if (section.isNotEmpty) {
      return [section];
    }
    
    // 尝试提取多行列表
    final listPattern = RegExp('(?:[-•*]|\\d+\\.)\\s*(.+)', multiLine: true);
    
    final items = <String>[];
    bool inSection = false;
    
    for (final line in content.split('\n')) {
      if (line.contains(primary) || line.contains(fallback)) {
        inSection = true;
        continue;
      }
      
      if (inSection && line.trim().isEmpty) {
        break;
      }
      
      if (inSection) {
        final match = listPattern.firstMatch(line);
        if (match != null) {
          items.add(match.group(1)!.trim());
        }
      }
    }
    
    return items;
  }
  
  /// 提取行动项
  static List<ActionItem> _extractActionItems(String content) {
    final items = <ActionItem>[];
    final parts = content.split(RegExp(r'行动项|待办事项'));
    final section = parts.length > 1 ? parts[1] : '';
    
    final itemPattern = RegExp(r'[-•*]\s*(.+?)(?:（(.+?)）)?(?:，(.+?))?$', multiLine: true);
    final matches = itemPattern.allMatches(section);
    
    for (final match in matches) {
      final task = match.group(1)?.trim() ?? '';
      final owner = match.group(2)?.trim();
      final deadline = match.group(3)?.trim();
      
      if (task.isNotEmpty) {
        items.add(ActionItem(
          task: task,
          owner: owner,
          deadline: deadline,
        ));
      }
    }
    
    return items;
  }
}

/// 会议摘要
class MeetingSummary {
  final String summary;
  final List<String> keyPoints;
  final List<String> decisions;
  final List<ActionItem> actionItems;
  final String nextSteps;
  final String rawContent;

  MeetingSummary({
    required this.summary,
    required this.keyPoints,
    required this.decisions,
    required this.actionItems,
    required this.nextSteps,
    required this.rawContent,
  });

  factory MeetingSummary.fromJson(Map<String, dynamic> json) {
    return MeetingSummary(
      summary: json['summary'] ?? '',
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
      decisions: List<String>.from(json['decisions'] ?? []),
      actionItems: (json['actionItems'] as List?)
          ?.map((item) => ActionItem.fromJson(item))
          .toList() ?? [],
      nextSteps: json['nextSteps'] ?? '',
      rawContent: json['rawContent'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'keyPoints': keyPoints,
      'decisions': decisions,
      'actionItems': actionItems.map((item) => item.toJson()).toList(),
      'nextSteps': nextSteps,
      'rawContent': rawContent,
    };
  }
}

/// 行动项
class ActionItem {
  final String task;
  final String? owner;
  final String? deadline;

  ActionItem({
    required this.task,
    this.owner,
    this.deadline,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      task: json['task'] ?? '',
      owner: json['owner'],
      deadline: json['deadline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'owner': owner,
      'deadline': deadline,
    };
  }
}

/// 转录片段（用于传入说话人信息）
class TranscriptSegment {
  final String text;
  final String? speakerId;
  final double? startTime;
  final double? endTime;

  TranscriptSegment({
    required this.text,
    this.speakerId,
    this.startTime,
    this.endTime,
  });
}