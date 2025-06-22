import 'dart:io';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../routes/app_pages.dart';
import '../../services/openai_service.dart';
import '../../services/storage_service.dart';

class MeetingDetailController extends GetxController {
  late Map<String, dynamic> meeting;
  final AudioPlayer audioPlayer = AudioPlayer();
  
  final RxBool isPlaying = false.obs;
  final RxBool isTranscribing = false.obs;
  final RxString transcription = ''.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    meeting = Get.arguments ?? {};
    
    // Initialize transcription if it exists
    if (meeting['transcription'] != null && meeting['transcription'].toString().isNotEmpty) {
      transcription.value = meeting['transcription'];
    }
    
    // Setup audio player listeners
    audioPlayer.onPositionChanged.listen((pos) {
      position.value = pos;
    });
    
    audioPlayer.onDurationChanged.listen((dur) {
      duration.value = dur;
    });
    
    audioPlayer.onPlayerComplete.listen((_) {
      isPlaying.value = false;
      position.value = Duration.zero;
    });
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }

  void viewFullSummary() {
    Get.toNamed(Routes.SUMMARY, arguments: meeting);
  }

  Future<void> togglePlayPause() async {
    try {
      if (meeting['audioPath'] == null || meeting['audioPath'].toString().isEmpty) {
        errorMessage.value = 'No audio file found';
        return;
      }

      if (isPlaying.value) {
        await audioPlayer.pause();
        isPlaying.value = false;
      } else {
        final audioFile = File(meeting['audioPath']);
        if (!audioFile.existsSync()) {
          errorMessage.value = 'Audio file not found';
          return;
        }
        
        await audioPlayer.play(DeviceFileSource(meeting['audioPath']));
        isPlaying.value = true;
      }
    } catch (e) {
      errorMessage.value = 'Error playing audio: $e';
      isPlaying.value = false;
    }
  }

  Future<void> seekTo(double value) async {
    final position = Duration(seconds: value.toInt());
    await audioPlayer.seek(position);
  }

  Future<void> transcribeAudio() async {
    try {
      if (meeting['audioPath'] == null || meeting['audioPath'].toString().isEmpty) {
        errorMessage.value = 'No audio file found';
        return;
      }

      final audioFile = File(meeting['audioPath']);
      if (!audioFile.existsSync()) {
        errorMessage.value = 'Audio file not found';
        return;
      }

      isTranscribing.value = true;
      errorMessage.value = '';

      // Read audio file
      final audioData = await audioFile.readAsBytes();
      
      // Transcribe using OpenAI
      final result = await OpenAIService.transcribeAudio(
        audioData: audioData,
        language: 'en',
      );

      transcription.value = result;
      
      // Update meeting data with transcription
      meeting['transcription'] = result;
      await StorageService.updateMeeting(meeting);

    } catch (e) {
      errorMessage.value = 'Error transcribing audio: $e';
    } finally {
      isTranscribing.value = false;
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}