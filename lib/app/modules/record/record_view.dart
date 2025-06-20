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
        actions: [
          Obx(
            () => controller.isRecording.value
                ? TextButton(
                    onPressed: controller.cancelRecording,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Meeting title input
              TextField(
                controller: controller.titleController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Title',
                  hintText: 'Enter meeting title',
                  prefixIcon: Icon(Icons.title),
                ),
                enabled: !controller.isRecording.value,
              ),
              const SizedBox(height: 32),
              
              // Recording indicator
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(
                        () => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: controller.isRecording.value ? 180 : 150,
                          height: controller.isRecording.value ? 180 : 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.isRecording.value
                                ? Colors.red.withOpacity(0.2)
                                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            boxShadow: controller.isRecording.value
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            controller.isRecording.value
                                ? Icons.mic
                                : Icons.mic_none,
                            size: 80,
                            color: controller.isRecording.value
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Recording time
                      Obx(
                        () => controller.isRecording.value
                            ? Column(
                                children: [
                                  Text(
                                    controller.recordingTime.value,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Recording...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              )
                            : Text(
                                'Tap to start recording',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pause/Resume button
                  Obx(
                    () => controller.isRecording.value
                        ? IconButton(
                            onPressed: controller.togglePause,
                            icon: Icon(
                              controller.isPaused.value
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              size: 32,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.all(16),
                            ),
                          )
                        : const SizedBox(width: 64),
                  ),
                  
                  // Main record button
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.toggleRecording,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                        backgroundColor: controller.isRecording.value
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                      child: Icon(
                        controller.isRecording.value
                            ? Icons.stop
                            : Icons.fiber_manual_record,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Save notes button
                  Obx(
                    () => controller.isRecording.value
                        ? IconButton(
                            onPressed: controller.addNote,
                            icon: const Icon(
                              Icons.note_add,
                              size: 32,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.all(16),
                            ),
                          )
                        : const SizedBox(width: 64),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.isRecording.value
                            ? 'Speak clearly and keep your device close'
                            : 'Find a quiet place for better audio quality',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}