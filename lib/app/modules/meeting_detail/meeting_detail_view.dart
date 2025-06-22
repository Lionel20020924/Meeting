import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'meeting_detail_controller.dart';

class MeetingDetailView extends GetView<MeetingDetailController> {
  const MeetingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.meeting['title'] ?? 'Meeting Detail'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meeting Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Title', controller.meeting['title'] ?? 'N/A'),
                      _buildInfoRow('Date', controller.meeting['date'] ?? 'N/A'),
                      _buildInfoRow('Duration', controller.meeting['duration'] ?? 'N/A'),
                      if (controller.meeting['audioPath'] != null)
                        _buildInfoRow('Audio', 'Recording available'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (controller.meeting['audioPath'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audio Recording',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() => Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    controller.isPlaying.value 
                                        ? Icons.pause_circle_filled 
                                        : Icons.play_circle_filled,
                                    size: 48,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: controller.togglePlayPause,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Slider(
                                        value: controller.position.value.inSeconds.toDouble(),
                                        min: 0,
                                        max: controller.duration.value.inSeconds.toDouble().clamp(0, double.infinity),
                                        onChanged: controller.duration.value.inSeconds > 0 
                                            ? controller.seekTo 
                                            : null,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(controller.formatDuration(controller.position.value)),
                                          Text(controller.formatDuration(controller.duration.value)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (controller.errorMessage.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transcription',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (controller.meeting['audioPath'] != null)
                            Obx(() => ElevatedButton.icon(
                              onPressed: controller.isTranscribing.value 
                                  ? null 
                                  : controller.transcribeAudio,
                              icon: controller.isTranscribing.value 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.mic),
                              label: Text(
                                controller.isTranscribing.value 
                                    ? 'Transcribing...' 
                                    : 'Transcribe Audio',
                              ),
                            )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(() => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          controller.transcription.value.isEmpty
                              ? 'Click "Transcribe Audio" to convert the audio recording to text.'
                              : controller.transcription.value,
                          style: const TextStyle(fontSize: 16),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.viewFullSummary,
                  child: const Text('View Full Summary'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}