import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };
  
  /// Convert audio to text using OpenAI Whisper API
  static Future<String> transcribeAudio({
    required Uint8List audioData,
    String model = 'whisper-1',
    String language = 'zh',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/audio/transcriptions'),
      );
      
      request.headers['Authorization'] = 'Bearer $_apiKey';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioData,
          filename: 'audio.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );
      
      request.fields['model'] = model;
      request.fields['language'] = language;
      request.fields['response_format'] = 'json';
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['text'] ?? '';
      } else {
        throw Exception('Failed to transcribe audio: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Error transcribing audio: $e');
    }
  }
  
  /// Generate chat completion
  static Future<String> generateChatCompletion({
    required String prompt,
    String model = 'gpt-3.5-turbo',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating chat completion: $e');
    }
  }
}