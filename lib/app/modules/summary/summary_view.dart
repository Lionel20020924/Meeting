import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'summary_controller.dart';

class SummaryView extends GetView<SummaryController> {
  const SummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.meetingData['title'] ?? 'Meeting Summary'),
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.summary.value.isNotEmpty) {
              return IconButton(
                onPressed: controller.regenerateSummary,
                icon: const Icon(Icons.refresh),
                tooltip: 'Regenerate Summary',
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            onPressed: controller.shareSummary,
            icon: const Icon(Icons.share),
            tooltip: 'Share Summary',
          ),
        ],
      ),
      body: Obx(() {
        // Show full loading screen only when loading transcript or initial load
        if (controller.isLoading.value || 
            (controller.isTranscribing.value && controller.transcript.value.isEmpty)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  controller.isTranscribing.value 
                      ? 'Transcribing Audio'
                      : controller.isGeneratingSummary.value
                          ? 'Generating Summary'
                          : 'Processing...',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.isTranscribing.value
                      ? 'Converting speech to text...'
                      : controller.isGeneratingSummary.value
                          ? 'Analyzing transcript and creating insights...'
                          : 'Preparing your meeting summary...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a few moments',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 32),
                // Progress indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 40,
                          color: controller.isTranscribing.value
                              ? Theme.of(context).primaryColor
                              : controller.transcript.value.isNotEmpty
                                  ? Colors.green
                                  : Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transcribe',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: controller.isTranscribing.value
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: controller.isTranscribing.value
                                ? Theme.of(context).primaryColor
                                : controller.transcript.value.isNotEmpty
                                    ? Colors.green
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Icon(
                      Icons.arrow_forward,
                      size: 24,
                      color: controller.transcript.value.isNotEmpty
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        Icon(
                          Icons.summarize,
                          size: 40,
                          color: controller.isGeneratingSummary.value
                              ? Theme.of(context).primaryColor
                              : controller.summary.value.isNotEmpty
                                  ? Colors.green
                                  : Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Summarize',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: controller.isGeneratingSummary.value
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: controller.isGeneratingSummary.value
                                ? Theme.of(context).primaryColor
                                : controller.summary.value.isNotEmpty
                                    ? Colors.green
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Top section: Collapsible Transcript
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                elevation: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Transcript header with expand/collapse
                    InkWell(
                      onTap: controller.toggleTranscriptExpansion,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(12),
                        bottom: Radius.circular(
                          controller.isTranscriptExpanded.value ? 0 : 12,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.vertical(
                            top: const Radius.circular(12),
                            bottom: Radius.circular(
                              controller.isTranscriptExpanded.value ? 0 : 12,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: controller.togglePlayPause,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  controller.isPlaying.value 
                                    ? Icons.pause_circle_filled 
                                    : Icons.play_circle_filled,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Audio Transcription',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    controller.transcript.value.isEmpty
                                        ? 'No transcription available'
                                        : '${controller.transcript.value.split(' ').length} words',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Audio duration
                            if (controller.totalDuration.value.inSeconds > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  controller.formatDuration(controller.totalDuration.value),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            // Expand/collapse icon
                            Icon(
                              controller.isTranscriptExpanded.value 
                                ? Icons.expand_less 
                                : Icons.expand_more,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expandable content
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: controller.isTranscriptExpanded.value
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(height: 1),
                            // Audio progress bar
                            if (controller.totalDuration.value.inSeconds > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      controller.formatDuration(controller.currentPosition.value),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                        ),
                                        child: Slider(
                                          value: controller.currentPosition.value.inSeconds.toDouble(),
                                          max: controller.totalDuration.value.inSeconds.toDouble(),
                                          onChanged: (value) {
                                            controller.seekTo(Duration(seconds: value.toInt()));
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                      controller.formatDuration(controller.totalDuration.value),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Transcript text
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: SingleChildScrollView(
                                  child: Text(
                                    controller.formattedTranscript.value.isEmpty
                                        ? 'No transcription available'
                                        : controller.formattedTranscript.value,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
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
            
            // Bottom section: Summary (takes remaining space)
            Expanded(
              child: Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined, 
                            color: Theme.of(context).colorScheme.secondary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Meeting Intelligence',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (controller.hasSummaryContent)
                                  Text(
                                    controller.summaryStats,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Prompt customization button
                          if (controller.transcript.value.isNotEmpty)
                            IconButton(
                              onPressed: () => _showPromptDialog(context),
                              icon: Icon(
                                controller.isUsingCustomPrompt.value 
                                    ? Icons.edit_note
                                    : Icons.edit_note_outlined,
                                color: controller.isUsingCustomPrompt.value 
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[600],
                              ),
                              tooltip: 'Customize Prompt',
                            ),
                          // Show generating status if summary is being generated
                          if (controller.isGeneratingSummary.value)
                            Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Generating...',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Summary content area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Meeting info
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
                                      controller.meetingData['title'] ?? 'Meeting',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Duration: ${controller.meetingData['duration'] ?? '00:00'}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Participants: ${controller.meetingData['participants'] ?? '1'}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Notes: ${controller.meetingData['notes']?.length ?? 0}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Summary, Key Points, and To-Do sections
                              const SizedBox(height: 20),
                              
                              // Summary Section
                              if (controller.summary.value.isNotEmpty) ...[
                                ..._buildSummarySection(context),
                              ],
                              
                              // Key Points Section
                              if (controller.keyPoints.isNotEmpty) ...[
                                ..._buildKeyPointsSection(context),
                              ],
                              
                              // To-Do List Section
                              if (controller.actionItems.isNotEmpty) ...[
                                ..._buildToDoSection(context),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom action bar
            Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.shareSummary,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: controller.finishAndReturn,
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
  
  // Build Summary Section
  List<Widget> _buildSummarySection(BuildContext context) {
    return [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.summarize,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
              controller.summary.value,
              style: const TextStyle(fontSize: 16, height: 1.6),
            )),
          ],
        ),
      ),
    ];
  }
  
  // Build Key Points Section
  List<Widget> _buildKeyPointsSection(BuildContext context) {
    return [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Key Points',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.keyPoints.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),
            ...controller.keyPoints.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    ];
  }
  
  // Build To-Do Section
  List<Widget> _buildToDoSection(BuildContext context) {
    return [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.checklist,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Action Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.actionItems.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),
            ...controller.actionItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => controller.toggleActionItemCompletion(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 12, top: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.error,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const SizedBox(),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    ];
  }
  
  // Show prompt customization dialog
  void _showPromptDialog(BuildContext context) {
    controller.promptController.text = controller.customPrompt.value;
    
    Get.dialog(
      AlertDialog(
        title: const Text('Customize Summary Prompt'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Customize how the AI analyzes your meeting transcript',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.promptController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your custom prompt...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Obx(() => Switch(
                    value: controller.isUsingCustomPrompt.value,
                    onChanged: (value) {
                      controller.isUsingCustomPrompt.value = value;
                      if (value && controller.customPrompt.value.isEmpty) {
                        controller.customPrompt.value = 'Please analyze the following meeting transcript and provide a detailed summary with key insights:';
                        controller.promptController.text = controller.customPrompt.value;
                      }
                    },
                  )),
                  const SizedBox(width: 8),
                  const Text('Use Custom Prompt'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.resetToDefaultPrompt();
              Get.back();
            },
            child: const Text('Reset to Default'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateCustomPrompt(controller.promptController.text);
              controller.saveCustomPrompt();
              Get.back();
              controller.regenerateSummary();
            },
            child: const Text('Apply & Regenerate'),
          ),
        ],
      ),
    );
  }
}