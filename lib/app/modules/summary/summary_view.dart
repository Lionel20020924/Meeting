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
        if (controller.isLoading.value) {
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
            // Top section: Full Transcript (scrollable)
            Expanded(
              flex: 1,
              child: Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: controller.togglePlayPause,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Obx(() => Icon(
                                controller.isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              )),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Audio Transcription',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Audio duration display
                          Obx(() {
                            if (controller.totalDuration.value.inSeconds > 0) {
                              return Text(
                                '${controller.formatDuration(controller.currentPosition.value)} / ${controller.formatDuration(controller.totalDuration.value)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ),
                      const Divider(height: 24),
                      // Audio progress bar
                      Obx(() {
                        if (controller.totalDuration.value.inSeconds > 0) {
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                ),
                                child: Slider(
                                  value: controller.currentPosition.value.inSeconds.toDouble(),
                                  max: controller.totalDuration.value.inSeconds.toDouble(),
                                  onChanged: (value) {
                                    controller.seekTo(Duration(seconds: value.toInt()));
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            controller.transcript.value.isEmpty
                                ? 'Transcribing audio...'
                                : controller.transcript.value,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom section: Summary (scrollable)
            Expanded(
              flex: 1,
              child: Card(
                margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.summarize, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Meeting Analysis',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Obx(() {
                                  if (controller.hasSummaryContent) {
                                    return Text(
                                      controller.summaryStats,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                          // Prompt customization button
                          if (controller.transcript.value.isNotEmpty)
                            IconButton(
                              onPressed: () => _showPromptDialog(context),
                              icon: Obx(() => Icon(
                                controller.isUsingCustomPrompt.value 
                                    ? Icons.edit_note
                                    : Icons.edit_note_outlined,
                                color: controller.isUsingCustomPrompt.value 
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[600],
                              )),
                              tooltip: 'Customize Prompt',
                            ),
                          if (controller.summary.value.isEmpty && controller.transcript.value.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: controller.generateSummaryForFirstTime,
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Generate'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 36),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
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
                                          controller.meetingData['duration'] ?? '00:00',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateTime.now().toString().substring(0, 16),
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Show prompt indicator and no summary message
                              if (controller.summary.value.isEmpty && controller.transcript.value.isNotEmpty) ...[
                                // Custom prompt indicator
                                Obx(() {
                                  if (controller.isUsingCustomPrompt.value && controller.customPrompt.value.isNotEmpty) {
                                    return Container(
                                      margin: const EdgeInsets.only(top: 16, bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.edit_note,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Custom Prompt Active',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            controller.customPrompt.value.length > 100
                                                ? '${controller.customPrompt.value.substring(0, 100)}...'
                                                : controller.customPrompt.value,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 40),
                                      Icon(
                                        Icons.summarize_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No summary generated yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Obx(() => Text(
                                        controller.isUsingCustomPrompt.value
                                            ? 'Click "Generate Summary" to use your custom prompt'
                                            : 'Click "Generate Summary" to create one',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                              
                              // Summary, Key Points, and To-Do sections
                              if (controller.summary.value.isNotEmpty || controller.keyPoints.isNotEmpty || controller.actionItems.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                
                                // Summary Section
                                if (controller.summary.value.isNotEmpty) ..._buildSummarySection(context),
                                
                                // Key Points Section
                                if (controller.keyPoints.isNotEmpty) ..._buildKeyPointsSection(context),
                                
                                // To-Do List Section
                                if (controller.actionItems.isNotEmpty) ..._buildToDoSection(context),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Done button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: controller.finishAndReturn,
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
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
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.summarize,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Meeting Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.summary.value,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            ],
          ),
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
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Theme.of(context).colorScheme.onTertiary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Key Points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.keyPoints.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...controller.keyPoints.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ];
  }
  
  // Build To-Do List Section
  List<Widget> _buildToDoSection(BuildContext context) {
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
              Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
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
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.checklist,
                    color: Theme.of(context).colorScheme.onSecondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Action Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.actionItems.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...controller.actionItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.transparent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ];
  }
  
  void _showPromptDialog(BuildContext context) {
    // Initialize prompt controller with current custom prompt
    final controller = Get.find<SummaryController>();
    controller.promptController.text = controller.customPrompt.value;
    
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note),
            SizedBox(width: 8),
            Text('Customize Summary Prompt'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle between default and custom prompt
              Obx(() => SwitchListTile(
                title: const Text('Use Custom Prompt'),
                subtitle: Text(
                  controller.isUsingCustomPrompt.value
                      ? 'Custom prompt will be used for summary generation'
                      : 'Default structured prompt will be used',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                value: controller.isUsingCustomPrompt.value,
                onChanged: (value) => controller.toggleCustomPrompt(),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
              const SizedBox(height: 16),
              // Custom prompt text field
              Obx(() {
                if (controller.isUsingCustomPrompt.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Custom Prompt:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.promptController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Enter your custom prompt here...\n\nExample: "Analyze this meeting and focus on technical decisions and next steps"',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: The meeting transcript will be automatically appended to your prompt.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Default Prompt:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The default prompt will analyze the transcript and provide:\n• Brief summary (2-3 sentences)\n• Key points discussed\n• Action items identified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          if (controller.isUsingCustomPrompt.value)
            TextButton(
              onPressed: () {
                controller.resetToDefaultPrompt();
                Get.back();
              },
              child: const Text('Reset to Default'),
            ),
          ElevatedButton(
            onPressed: () {
              if (controller.isUsingCustomPrompt.value) {
                controller.saveCustomPrompt();
              }
              Get.back();
            },
            child: Text(
              controller.isUsingCustomPrompt.value ? 'Save Prompt' : 'Done',
            ),
          ),
        ],
      ),
    );
  }
}