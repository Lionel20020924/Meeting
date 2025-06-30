import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
  static const String _modelVersion = '2ee68234275d2b49c7c71c3091eb29c4c5e0b825b4ce96bc56decc40bad4ab38';
  
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
      // Step 1: First upload audio to a temporary service or use base64
      final audioUrl = await _uploadAudioToTempStorage(audioData);
      
      // Step 2: Create prediction with JSON body
      final prediction = await _createPrediction(
        audioUrl: audioUrl,
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

      // Step 3: Poll for completion
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

  /// Upload audio to temporary storage (using file.io or similar service)
  static Future<String> _uploadAudioToTempStorage(Uint8List audioData) async {
    try {
      // Use file.io for temporary storage (expires after 14 days)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://file.io'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioData,
          filename: 'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
        ),
      );
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        if (json['success'] == true && json['link'] != null) {
          return json['link'];
        }
      }
      
      throw Exception('Failed to upload audio to temporary storage');
    } catch (e) {
      // Fallback: use data URL
      final base64Audio = base64Encode(audioData);
      return 'data:audio/wav;base64,$base64Audio';
    }
  }

  /// Create a prediction on Replicate
  static Future<Map<String, dynamic>> _createPrediction({
    required String audioUrl,
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
    // Build input parameters
    final input = <String, dynamic>{
      'audio_file': audioUrl,
      'align_output': alignOutput,
      'batch_size': batchSize,
      'temperature': temperature,
      'debug': debug,
    };
    
    if (language != null && language.isNotEmpty) {
      input['language'] = language;
    }
    
    if (diarization) {
      input['diarization'] = true;
      if (huggingfaceAccessToken != null && huggingfaceAccessToken.isNotEmpty) {
        input['huggingface_access_token'] = huggingfaceAccessToken;
      }
      if (minSpeakers != null) {
        input['min_speakers'] = minSpeakers;
      }
      if (maxSpeakers != null) {
        input['max_speakers'] = maxSpeakers;
      }
    }
    
    // Create request body
    final requestBody = {
      'version': _modelVersion,
      'input': input,
    };
    
    final response = await http.post(
      Uri.parse('$_baseUrl/predictions'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create prediction: ${response.statusCode} - ${response.body}');
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