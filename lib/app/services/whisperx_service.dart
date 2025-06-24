import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class WhisperXSegment {
  final double start;
  final double end;
  final String text;
  final String? speaker;

  WhisperXSegment({
    required this.start,
    required this.end,
    required this.text,
    this.speaker,
  });

  factory WhisperXSegment.fromJson(Map<String, dynamic> json) {
    return WhisperXSegment(
      start: (json['start'] as num?)?.toDouble() ?? 0.0,
      end: (json['end'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] as String? ?? '',
      speaker: json['speaker'] as String?,
    );
  }
}

class WhisperXResult {
  final List<WhisperXSegment> segments;
  final String detectedLanguage;
  final String fullText;

  WhisperXResult({
    required this.segments,
    required this.detectedLanguage,
    required this.fullText,
  });

  factory WhisperXResult.fromJson(Map<String, dynamic> json) {
    final segments = <WhisperXSegment>[];
    if (json['segments'] is List) {
      for (final segment in json['segments']) {
        if (segment is Map<String, dynamic>) {
          segments.add(WhisperXSegment.fromJson(segment));
        }
      }
    }

    // Combine all segment texts to create full text
    final fullText = segments.map((s) => s.text).join(' ').trim();

    return WhisperXResult(
      segments: segments,
      detectedLanguage: json['detected_language'] as String? ?? 'unknown',
      fullText: fullText,
    );
  }
}

class WhisperXService {
  static const String _baseUrl = 'https://api.replicate.com/v1';
  static const String _modelOwner = 'victor-upmeet';
  static const String _modelName = 'whisperx';
  
  static String get _apiKey => dotenv.env['REPLICATE_API_KEY'] ?? '';
  
  static Map<String, String> get _headers => {
    'Authorization': 'Token $_apiKey',
    'Content-Type': 'application/json',
  };

  /// Transcribe audio using WhisperX via Replicate API
  static Future<WhisperXResult> transcribeAudio({
    required Uint8List audioData,
    String? language,
    bool diarization = false,
    String? huggingfaceAccessToken,
    bool alignOutput = true,
    int batchSize = 64,
    double temperature = 0.0,
    int? minSpeakers,
    int? maxSpeakers,
    bool debug = false,
  }) async {
    try {
      // Step 1: Create prediction with file upload
      final prediction = await _createPrediction(
        audioData: audioData,
        language: language,
        diarization: diarization,
        huggingfaceAccessToken: huggingfaceAccessToken,
        alignOutput: alignOutput,
        batchSize: batchSize,
        temperature: temperature,
        minSpeakers: minSpeakers,
        maxSpeakers: maxSpeakers,
        debug: debug,
      );

      final predictionId = prediction['id'] as String;

      // Step 2: Poll for completion
      final result = await _pollPredictionStatus(predictionId);

      if (result['status'] == 'succeeded') {
        final output = result['output'];
        if (output != null) {
          return WhisperXResult.fromJson(output);
        } else {
          throw Exception('WhisperX returned empty output');
        }
      } else if (result['status'] == 'failed') {
        final error = result['error'] ?? 'Unknown error';
        throw Exception('WhisperX prediction failed: $error');
      } else {
        throw Exception('WhisperX prediction did not complete successfully');
      }
    } catch (e) {
      throw Exception('Error with WhisperX transcription: $e');
    }
  }

  /// Create a prediction on Replicate
  static Future<Map<String, dynamic>> _createPrediction({
    required Uint8List audioData,
    String? language,
    bool diarization = false,
    String? huggingfaceAccessToken,
    bool alignOutput = true,
    int batchSize = 64,
    double temperature = 0.0,
    int? minSpeakers,
    int? maxSpeakers,
    bool debug = false,
  }) async {
    // Create multipart request for file upload
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/predictions'),
    );

    request.headers['Authorization'] = 'Token $_apiKey';

    // Add the audio file
    request.files.add(
      http.MultipartFile.fromBytes(
        'input[audio_file]',
        audioData,
        filename: 'audio.wav',
        contentType: MediaType('audio', 'wav'),
      ),
    );

    // Add other input parameters as form fields
    request.fields['version'] = '$_modelOwner/$_modelName';
    request.fields['input[align_output]'] = alignOutput.toString();
    request.fields['input[batch_size]'] = batchSize.toString();
    request.fields['input[temperature]'] = temperature.toString();
    request.fields['input[debug]'] = debug.toString();

    if (language != null) {
      request.fields['input[language]'] = language;
    }

    if (diarization) {
      request.fields['input[diarization]'] = 'true';
      if (huggingfaceAccessToken != null) {
        request.fields['input[huggingface_access_token]'] = huggingfaceAccessToken;
      }
      if (minSpeakers != null) {
        request.fields['input[min_speakers]'] = minSpeakers.toString();
      }
      if (maxSpeakers != null) {
        request.fields['input[max_speakers]'] = maxSpeakers.toString();
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to create prediction: ${response.statusCode} - $responseBody');
    }
  }

  /// Poll the prediction status until completion
  static Future<Map<String, dynamic>> _pollPredictionStatus(String predictionId) async {
    const maxAttempts = 60; // 5 minutes with 5-second intervals
    const pollInterval = Duration(seconds: 5);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final response = await http.get(
        Uri.parse('$_baseUrl/predictions/$predictionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final status = result['status'] as String;

        if (status == 'succeeded' || status == 'failed' || status == 'canceled') {
          return result;
        }

        // Wait before polling again
        await Future.delayed(pollInterval);
      } else {
        throw Exception('Failed to get prediction status: ${response.statusCode} - ${response.body}');
      }
    }

    throw Exception('WhisperX transcription timed out after ${maxAttempts * pollInterval.inSeconds} seconds');
  }

  /// Simple transcription method that returns just the text (for compatibility)
  static Future<String> transcribeAudioSimple({
    required Uint8List audioData,
    String? language = 'zh',
  }) async {
    final result = await transcribeAudio(
      audioData: audioData,
      language: language,
      diarization: false,
      alignOutput: false, // Faster processing
    );
    
    return result.fullText;
  }
}