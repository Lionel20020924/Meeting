import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'post_recording_controller.dart';

class PostRecordingView extends GetView<PostRecordingController> {
  const PostRecordingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('录音完成'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  controller.shareRecording();
                  break;
                case 'details':
                  controller.viewMeetingDetails();
                  break;
                case 'delete':
                  _showDeleteConfirmation(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('分享录音'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('详细信息'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('删除录音', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Meeting Title Section
                  _buildTitleSection(context),
                  const SizedBox(height: 16),
                  
                  // Audio Preview Section
                  _buildAudioPreviewSection(context),
                  const SizedBox(height: 16),
                  
                  // Transcription Preview Section
                  _buildTranscriptionPreviewSection(context),
                  const SizedBox(height: 16),
                  
                  // Tags Section
                  _buildTagsSection(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Bottom Action Buttons
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editable Title
            Obx(() => controller.isEditingTitle.value
                ? TextField(
                    controller: controller.titleController,
                    autofocus: true,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      hintText: '输入会议标题',
                    ),
                    onSubmitted: (_) => controller.saveTitle(),
                  )
                : InkWell(
                    onTap: controller.startEditingTitle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.meetingData['title'] ?? 'Untitled Meeting',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 8),
            // Meeting Metadata
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.meetingData['duration'] ?? '00:00',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.getFileSize(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPreviewSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '录音预览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Audio Player
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Progress Bar
                  Obx(() {
                    final position = controller.currentPosition.value;
                    final duration = controller.totalDuration.value;
                    final progress = duration.inMilliseconds > 0 
                        ? position.inMilliseconds / duration.inMilliseconds 
                        : 0.0;
                    
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: controller.isPlayingPreview.value
                                ? (value) {
                                    final newPosition = Duration(
                                      milliseconds: (value * duration.inMilliseconds).round(),
                                    );
                                    controller.seekTo(newPosition);
                                  }
                                : null,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _formatDuration(duration),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  // Play Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: controller.skipBackward,
                        icon: const Icon(Icons.replay_10),
                        tooltip: '后退 10 秒',
                      ),
                      Obx(() => IconButton(
                        onPressed: controller.togglePlayPause,
                        icon: Icon(
                          controller.isPlayingPreview.value 
                              ? Icons.pause_circle_filled 
                              : Icons.play_circle_filled,
                          size: 48,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                      )),
                      IconButton(
                        onPressed: controller.skipForward,
                        icon: const Icon(Icons.forward_10),
                        tooltip: '前进 10 秒',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionPreviewSection(BuildContext context) {
    final transcription = controller.meetingData['transcription']?.toString() ?? '';
    if (transcription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_snippet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '转录预览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '实时转录',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transcription.length > 200 
                        ? '${transcription.substring(0, 200)}...' 
                        : transcription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (transcription.length > 200) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        // Show full transcription in a dialog
                        _showFullTranscription(context, transcription);
                      },
                      icon: const Icon(Icons.expand_more, size: 18),
                      label: const Text('展开查看全部'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    final tags = controller.meetingData['tags'] as List<String>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.label_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '标签',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    // Remove tag
                    tags.remove(tag);
                    controller.meetingData['tags'] = tags;
                  },
                )),
                ActionChip(
                  label: const Text('添加标签'),
                  avatar: const Icon(Icons.add, size: 18),
                  onPressed: controller.addTags,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Primary Action
          Obx(() => SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.isGeneratingSummary.value 
                  ? null 
                  : controller.generateSummaryAndSave,
              icon: controller.isGeneratingSummary.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                controller.isGeneratingSummary.value 
                    ? '正在处理...' 
                    : '继续处理并生成摘要',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )),
          const SizedBox(height: 12),
          // Secondary Action
          Obx(() => SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isSaving.value 
                  ? null 
                  : controller.saveWithoutSummary,
              icon: controller.isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                controller.isSaving.value 
                    ? '正在保存...' 
                    : '仅保存录音',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('删除录音'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除这段录音吗？'),
            SizedBox(height: 8),
            Text(
              '此操作不可恢复。',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.discardRecording();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showFullTranscription(BuildContext context, String transcription) {
    Get.dialog(
      Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.text_snippet),
                    const SizedBox(width: 8),
                    const Text(
                      '完整转录',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(transcription),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '今天';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}