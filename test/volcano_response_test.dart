import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/app/services/volcano_engine/asr_service.dart';

void main() {
  group('Volcano Engine Response Parsing Tests', () {
    test('Parse successful transcription response', () {
      // 模拟火山引擎成功响应
      final volcanoResponse = {
        "audio_info": {"duration": 4213},
        "result": {
          "additions": {"duration": 4213},
          "text": "你好，穿线，你好。",
          "utterances": [
            {
              "end_time": 3780,
              "start_time": 900,
              "text": "你好，穿线，你好。",
              "words": [
                {"confidence": 0, "end_time": 1180, "start_time": 900, "text": "你"},
                {"confidence": 0, "end_time": 1700, "start_time": 1180, "text": "好"},
                {"confidence": 0, "end_time": 2140, "start_time": 2100, "text": "穿"},
                {"confidence": 0, "end_time": 2460, "start_time": 2420, "text": "线"},
                {"confidence": 0, "end_time": 3220, "start_time": 2860, "text": "你"},
                {"confidence": 0, "end_time": 3780, "start_time": 3220, "text": "好"}
              ]
            }
          ]
        }
      };

      // 解析响应
      final result = ASRTaskResult.fromVolcanoResponse('test-task-id', volcanoResponse);

      // 验证结果
      expect(result.taskId, equals('test-task-id'));
      expect(result.status, equals('success'));
      expect(result.metadata?['transcript_text'], equals('你好，穿线，你好。'));
      expect(result.segments, isNotNull);
      expect(result.segments!.length, equals(1));
      
      // 验证segment
      final segment = result.segments!.first;
      expect(segment.text, equals('你好，穿线，你好。'));
      expect(segment.startTime, equals(900.0));
      expect(segment.endTime, equals(3780.0));
      expect(segment.words, isNotNull);
      expect(segment.words!.length, equals(6));
      
      // 验证第一个词
      final firstWord = segment.words!.first;
      expect(firstWord.word, equals('你'));
      expect(firstWord.startTime, equals(900.0));
      expect(firstWord.endTime, equals(1180.0));
      
      print('✅ Volcano Engine response parsing test passed!');
      print('Transcribed text: ${result.metadata?['transcript_text']}');
      print('Word count: ${segment.words!.length}');
    });
  });
}