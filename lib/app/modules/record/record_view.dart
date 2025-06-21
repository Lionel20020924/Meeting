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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: controller.exitRecording,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Recording indicator
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated recording indicator
                      Obx(
                        () => TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(
                            begin: controller.isRecording.value ? 1.0 : 0.9,
                            end: controller.isRecording.value ? 1.1 : 0.9,
                          ),
                          onEnd: () {
                            if (controller.isRecording.value) {
                              controller.toggleAnimation();
                            }
                          },
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: controller.isRecording.value
                                      ? Colors.red.withOpacity(0.2)
                                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  boxShadow: controller.isRecording.value
                                      ? [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 30,
                                            spreadRadius: 10,
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
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Recording time
                      Obx(
                        () => controller.isRecording.value
                            ? Column(
                                children: [
                                  Text(
                                    controller.recordingTime.value,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        controller.isPaused.value
                                            ? 'Paused'
                                            : 'Recording',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Text(
                                    'Ready to record',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the button below to start',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                  ),
                                ],
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
                                  Theme.of(context).colorScheme.surfaceVariant,
                              padding: const EdgeInsets.all(16),
                            ),
                          )
                        : const SizedBox(width: 64),
                  ),
                  
                  // Main record button
                  Obx(
                    () => GestureDetector(
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
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          controller.isRecording.value
                              ? Icons.stop
                              : Icons.fiber_manual_record,
                          size: controller.isRecording.value ? 40 : 48,
                          color: Colors.white,
                        ),
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
                                  Theme.of(context).colorScheme.surfaceVariant,
                              padding: const EdgeInsets.all(16),
                            ),
                          )
                        : const SizedBox(width: 64),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Tips or notes count
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.isRecording.value
                            ? Icons.tips_and_updates
                            : Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.isRecording.value
                              ? controller.notes.isEmpty
                                  ? 'Tap the note button to add timestamps'
                                  : '${controller.notes.length} notes added'
                              : 'Find a quiet place for better quality',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}