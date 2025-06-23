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
      body: Column(
        children: [
          // Main content area - takes 7/8 of screen
          Expanded(
            flex: 7,
            child: Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: controller.isRecording.value
                    ? _buildRecordingView(context)
                    : _buildWelcomeView(context),
              ),
            ),
          ),
          
          // Bottom control area - takes 1/8 of screen
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: _buildControls(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Welcome animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.mic_none,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Record',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start capturing your meeting',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Usage tips
          _buildCompactTipCard(
            context,
            Icons.record_voice_over,
            'Speak Clearly',
            'Position device 1-2 feet away and speak naturally',
            Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildCompactTipCard(
            context,
            Icons.note_add,
            'Add Notes',
            'Tap the note button to mark important moments',
            Colors.green,
          ),
          const SizedBox(height: 10),
          _buildCompactTipCard(
            context,
            Icons.translate,
            'Auto Transcription',
            'Chinese language supported with real-time conversion',
            Colors.orange,
          ),
          const SizedBox(height: 10),
          _buildCompactTipCard(
            context,
            Icons.cloud_done,
            'Auto-Save',
            'Your recording is automatically saved when you stop',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recording status
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  // Animated recording indicator
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 1),
                    tween: Tween(begin: 0.5, end: 1.0),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: value),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                    onEnd: () {
                      controller.toggleAnimation();
                    },
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recording in Progress',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(() => Text(
                        'Duration: ${controller.recordingTime.value}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      )),
                    ],
                  ),
                  const Spacer(),
                  // Large time display
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.recordingTime.value,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  )),
                ],
              ),
            ),
            
            // Transcription
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.isTranscribing.value)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Transcribing...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  controller.transcribedText.value.isEmpty
                      ? 'Start speaking to see transcription...'
                      : controller.transcribedText.value,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: controller.transcribedText.value.isEmpty
                        ? Colors.grey[600]
                        : Colors.black87,
                  ),
                ),
              ],
            )),
            
            // Notes
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Action buttons when recording
          Obx(() => controller.isRecording.value
              ? Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Pause/Resume button
                      IconButton(
                        onPressed: controller.togglePause,
                        icon: Obx(() => Icon(
                          controller.isPaused.value 
                            ? Icons.play_arrow 
                            : Icons.pause,
                          size: 28,
                        )),
                        tooltip: controller.isPaused.value ? 'Resume' : 'Pause',
                      ),
                      // Add note button
                      IconButton(
                        onPressed: controller.addNote,
                        icon: const Icon(Icons.note_add, size: 28),
                        tooltip: 'Add Note',
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: 100),
          ),
          
          // Main recording button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => GestureDetector(
                onTap: controller.toggleRecording,
                child: Container(
                  width: 60,
                  height: 60,
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
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      controller.isRecording.value
                          ? Icons.stop
                          : Icons.mic,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 4),
              // Status text
              Obx(() => Text(
                controller.isRecording.value
                    ? (controller.isPaused.value ? 'Paused' : 'Recording')
                    : 'Tap to start',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: controller.isRecording.value
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
              )),
            ],
          ),
          
          // Spacer for balance
          Obx(() => controller.isRecording.value
              ? const Expanded(child: SizedBox())
              : const SizedBox(width: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTipCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}