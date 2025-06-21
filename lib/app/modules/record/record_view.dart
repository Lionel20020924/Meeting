import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'record_controller.dart';

class RecordView extends GetView<RecordController> {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Meeting'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: controller.exitRecording,
        ),
      ),
      body: Stack(
        children: [
          // Main content area for transcribed text
          Column(
            children: [
              // Transcription display area
              Expanded(
                child: Obx(
                  () => controller.isRecording.value
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            reverse: true, // Auto-scroll to bottom as new text appears
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (controller.isRecording.value)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Recording...',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Obx(() => Text(
                                          controller.recordingTime.value,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        )),
                                      ],
                                    ),
                                  ),
                                // Recording status
                                Text(
                                  'Recording in progress...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.5,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                // Display notes
                                if (controller.notes.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Notes',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...controller.notes.map((note) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'At ${note['time']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          note['note'] ?? '',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mic_none,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Ready to Record',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button below to start',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
          
          // Bottom recording control
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Action buttons when recording
                    Obx(() => controller.isRecording.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Pause/Resume button
                              IconButton(
                                onPressed: controller.togglePause,
                                icon: Obx(() => Icon(
                                  controller.isPaused.value 
                                    ? Icons.play_arrow 
                                    : Icons.pause,
                                  size: 32,
                                )),
                                tooltip: controller.isPaused.value ? 'Resume' : 'Pause',
                              ),
                              // Add note button
                              IconButton(
                                onPressed: controller.addNote,
                                icon: const Icon(Icons.note_add, size: 32),
                                tooltip: 'Add Note',
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Main recording button
                    Obx(() => GestureDetector(
                      onTap: controller.toggleRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.isRecording.value
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (controller.isRecording.value
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.primary)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            controller.isRecording.value
                                ? Icons.stop
                                : Icons.mic,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    )),
                    
                    const SizedBox(height: 12),
                    
                    // Status text
                    Obx(() => Text(
                      controller.isRecording.value
                          ? (controller.isPaused.value ? 'Paused' : 'Recording...')
                          : 'Tap to start',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: controller.isRecording.value
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                    )),
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}