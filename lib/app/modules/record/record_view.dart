import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/smooth_audio_waveform.dart';
import 'record_controller.dart';

class RecordView extends GetView<RecordController> {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录音'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: controller.exitRecording,
        ),
      ),
      body: Column(
        children: [
          // Main content area - takes remaining space
          Expanded(
            child: Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: controller.isRecording.value
                    ? _buildRecordingView(context)
                    : _buildWelcomeView(context),
              ),
            ),
          ),
          
          // Bottom control area - using intrinsic height
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: _buildControls(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Welcome animation with waveform
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
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // Static waveform preview
                Container(
                  height: 30,
                  width: 200,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(15, (index) {
                      final height = 8.0 + (index % 3) * 4.0;
                      return Container(
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '准备录音',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮开始录制会议',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          
          // Usage tips
          _buildCompactTipCard(
            context,
            Icons.record_voice_over,
            '清晰发音',
            '设备距离 30-60 厘米，自然说话',
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildCompactTipCard(
            context,
            Icons.note_add,
            '添加笔记',
            '点击笔记按钮标记重要时刻',
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildCompactTipCard(
            context,
            Icons.translate,
            '自动转录',
            '支持中文实时语音转文字',
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildCompactTipCard(
            context,
            Icons.cloud_done,
            '自动保存',
            '录音结束后自动保存到本地',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView(BuildContext context) {
    return Column(
      children: [
        // Recording status at the top
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.08),
                Colors.red.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1.5,
              ),
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
                    width: 12,
                    height: 12,
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
              const Text(
                '正在录音',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Time display
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.recordingTime.value,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        
        // Audio Waveform Visualization
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Center(
            child: Obx(() => FlowingWaveform(
              waveformData: controller.waveformData,
              height: 100,
              color: controller.isPaused.value ? Colors.grey : Colors.red,
              isActive: controller.isRecording.value && !controller.isPaused.value,
            )),
          ),
        ),
        
        // Transcription area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transcription header
                Row(
                  children: [
                    Icon(
                      Icons.text_snippet_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '实时转录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Obx(() => controller.isTranscribing.value
                        ? Row(
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
                                '转录中...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Transcription content
                Expanded(
                  child: SingleChildScrollView(
                    child: Obx(() => Text(
                      controller.transcribedText.value.isEmpty
                          ? '开始说话，这里将显示转录内容...'
                          : controller.transcribedText.value,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: controller.transcribedText.value.isEmpty
                            ? Colors.grey[600]
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    )),
                  ),
                ),
                
                // Notes section at bottom
                Obx(() => controller.notes.isNotEmpty
                    ? Column(
                        children: [
                          const Divider(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '笔记 (${controller.notes.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: controller.notes.length,
                              itemBuilder: (context, index) {
                                final note = controller.notes[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '@ ${note['time']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        note['note'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Action buttons when recording
          Obx(() => controller.isRecording.value
              ? Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Pause/Resume button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: controller.togglePause,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Obx(() => Icon(
                              controller.isPaused.value 
                                ? Icons.play_arrow_rounded 
                                : Icons.pause_rounded,
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            )),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Add note button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: controller.addNote,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.note_add_rounded,
                              size: 24,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: 100),
          ),
          
          // Main recording button
          Obx(() => GestureDetector(
            onTap: controller.toggleRecording,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                controller.isRecording.value
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.red.shade600, Colors.red.shade800],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.stop_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      )
                    : AnimatedBuilder(
                        animation: controller.pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: controller.pulseAnimation.value,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(
                                      alpha: 0.4 * controller.pulseAnimation.value,
                                    ),
                                    blurRadius: 20 * controller.pulseAnimation.value,
                                    spreadRadius: 2 * controller.pulseAnimation.value,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(
                                      alpha: 0.2 * controller.pulseAnimation.value,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 4),
                // Status text
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: controller.isRecording.value
                        ? Colors.red.shade700
                        : Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                  child: Text(
                    controller.isRecording.value
                        ? (controller.isPaused.value ? '已暂停' : '录音中')
                        : '点击开始',
                  ),
                ),
              ],
            ),
          )),
          
          // Spacer for balance
          Obx(() => controller.isRecording.value
              ? const Expanded(child: SizedBox())
              : const SizedBox(width: 80),
          ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
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