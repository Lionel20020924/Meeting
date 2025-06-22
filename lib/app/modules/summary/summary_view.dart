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
          IconButton(
            onPressed: controller.regenerateSummary,
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate Summary',
          ),
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
                          Icon(Icons.mic, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Audio Transcription',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
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
                          const Text(
                            'Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
                              
                              // Summary text
                              if (controller.summary.value.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  controller.summary.value,
                                  style: const TextStyle(fontSize: 16, height: 1.5),
                                ),
                              ],
                              
                              // Key Points
                              if (controller.keyPoints.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'Key Points:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...controller.keyPoints.map((point) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                              
                              // Action Items  
                              if (controller.actionItems.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'Action Items:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...controller.actionItems.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_box_outline_blank,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
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
}