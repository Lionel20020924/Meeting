import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'meeting_detail_controller.dart';

class MeetingDetailView extends GetView<MeetingDetailController> {
  const MeetingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
          ),
          // Main content
          CustomScrollView(
            slivers: [
              // Custom App Bar with meeting info
              _buildCustomAppBar(context),
              // Meeting content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Audio Player Card
                      if (controller.meeting['audioPath'] != null)
                        _buildAudioPlayerCard(context),
                      const SizedBox(height: 16),
                      // Transcription Card
                      _buildTranscriptionCard(context),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating Action Buttons
          _buildFloatingActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          controller.meeting['title'] ?? 'Meeting Detail',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Pattern overlay
              Opacity(
                opacity: 0.1,
                child: Center(
                  child: Icon(
                    Icons.meeting_room_outlined,
                    size: 200,
                    color: Colors.white,
                  ),
                ),
              ),
              // Meeting info
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderInfoChip(
                      Icons.calendar_today,
                      controller.meeting['date'] ?? 'No date',
                    ),
                    const SizedBox(height: 8),
                    _buildHeaderInfoChip(
                      Icons.timer,
                      controller.meeting['duration'] ?? '00:00',
                    ),
                    if (controller.meeting['audioPath'] != null) ...[
                      const SizedBox(height: 8),
                      _buildHeaderInfoChip(
                        Icons.mic,
                        'Audio recording available',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Card(
            elevation: 8,
            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.audiotrack,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Audio Recording',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Obx(() => Column(
                      children: [
                        // Waveform visualization placeholder
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(30, (index) {
                                final isActive = controller.duration.value.inSeconds > 0 &&
                                    index < (controller.position.value.inSeconds / 
                                    controller.duration.value.inSeconds * 30).round();
                                return Container(
                                  width: 3,
                                  height: 20 + (index % 3) * 10.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Play controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Skip backward
                            IconButton(
                              icon: const Icon(Icons.replay_10),
                              iconSize: 32,
                              onPressed: () => controller.skipBackward(),
                            ),
                            const SizedBox(width: 16),
                            // Play/Pause button
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    controller.isPlaying.value 
                                        ? Icons.pause_rounded 
                                        : Icons.play_arrow_rounded,
                                    key: ValueKey(controller.isPlaying.value),
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: controller.togglePlayPause,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Skip forward
                            IconButton(
                              icon: const Icon(Icons.forward_10),
                              iconSize: 32,
                              onPressed: () => controller.skipForward(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Theme.of(context).colorScheme.primary,
                            inactiveTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            thumbColor: Theme.of(context).colorScheme.primary,
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: Slider(
                            value: controller.position.value.inSeconds.toDouble(),
                            min: 0,
                            max: controller.duration.value.inSeconds.toDouble().clamp(0.1, double.infinity),
                            onChanged: controller.duration.value.inSeconds > 0 
                                ? controller.seekTo 
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                controller.formatDuration(controller.position.value),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                controller.formatDuration(controller.duration.value),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (controller.errorMessage.value.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.errorMessage.value,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranscriptionCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Add delay effect
        final delayedValue = value < 0.25 ? 0.0 : (value - 0.25) / 0.75;
        return Transform.translate(
          offset: Offset(0, 30 * (1 - delayedValue)),
          child: Opacity(
            opacity: delayedValue,
            child: Card(
              elevation: 8,
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.text_snippet,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Transcription',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (controller.meeting['audioPath'] != null)
                          Obx(() => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: controller.transcription.value.isNotEmpty
                                ? Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded),
                                        onPressed: controller.copyTranscription,
                                        tooltip: 'Copy transcription',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.search_rounded),
                                        onPressed: controller.toggleSearch,
                                        tooltip: 'Search in transcription',
                                      ),
                                    ],
                                  )
                                : ElevatedButton.icon(
                                    onPressed: controller.isTranscribing.value 
                                        ? null 
                                        : controller.transcribeAudio,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: controller.isTranscribing.value 
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.mic),
                                    label: Text(
                                      controller.isTranscribing.value 
                                          ? 'Transcribing...' 
                                          : 'Transcribe',
                                    ),
                                  ),
                          )),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search bar (if search is active)
                    Obx(() => controller.showSearch.value
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: controller.searchController,
                              onChanged: controller.searchInTranscription,
                              decoration: InputDecoration(
                                hintText: 'Search in transcription...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: controller.toggleSearch,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    ),
                    // Transcription content
                    Obx(() => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      constraints: BoxConstraints(
                        maxHeight: controller.transcription.value.isEmpty ? 100 : 400,
                      ),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: controller.transcription.value.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.text_snippet_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.meeting['audioPath'] != null
                                        ? 'Click "Transcribe" to convert audio to text'
                                        : 'No transcription available',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: controller.transcriptionSegments.isEmpty
                                  ? Text(
                                      controller.highlightedTranscription.value.isEmpty
                                          ? controller.formattedTranscription.value
                                          : controller.highlightedTranscription.value,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                    )
                                  : _buildSpeakerSeparatedTranscript(context),
                            ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeakerSeparatedTranscript(BuildContext context) {
    // Group consecutive segments by speaker
    final List<Map<String, dynamic>> speakerGroups = [];
    String? currentSpeaker;
    List<dynamic> currentGroup = [];
    
    for (final segment in controller.transcriptionSegments) {
      final speakerId = segment['speakerId'] as String?;
      
      if (speakerId != currentSpeaker) {
        if (currentGroup.isNotEmpty) {
          speakerGroups.add({
            'speakerId': currentSpeaker,
            'segments': List.from(currentGroup),
          });
        }
        currentSpeaker = speakerId;
        currentGroup = [segment];
      } else {
        currentGroup.add(segment);
      }
    }
    
    // Add the last group
    if (currentGroup.isNotEmpty) {
      speakerGroups.add({
        'speakerId': currentSpeaker,
        'segments': currentGroup,
      });
    }
    
    // Build the UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: speakerGroups.expand((group) {
        final speakerId = group['speakerId'] as String?;
        final segments = group['segments'] as List<dynamic>;
        // Format speaker label based on speaker ID
        String speakerLabel;
        if (speakerId == null) {
          speakerLabel = 'Unknown Speaker';
        } else {
          // Try to parse speaker ID as a number and display as "Speaker 1", "Speaker 2", etc.
          final speakerNumber = int.tryParse(speakerId.toString());
          if (speakerNumber != null) {
            speakerLabel = 'Speaker ${speakerNumber + 1}';
          } else {
            speakerLabel = 'Speaker $speakerId';
          }
        }
        final speakerColor = _getSpeakerColor(speakerId);
        
        return [
          // Speaker label
          Container(
            margin: const EdgeInsets.only(bottom: 8, top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: speakerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: speakerColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: speakerColor,
                ),
                const SizedBox(width: 6),
                Text(
                  speakerLabel,
                  style: TextStyle(
                    color: speakerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Speaker's text
          Container(
            margin: const EdgeInsets.only(left: 24, bottom: 12),
            child: Text(
              segments.map((s) => s['text'] ?? '').join(' '),
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }
  
  Color _getSpeakerColor(String? speakerId) {
    if (speakerId == null) return Colors.grey;
    
    // Generate consistent colors based on speaker ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
    ];
    
    // Use speaker ID to get a consistent color
    final index = speakerId.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Share button
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              final delayedValue = value < 0.4 ? 0.0 : (value - 0.4) / 0.6;
              return Transform.scale(
                scale: delayedValue,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: 'share',
                  onPressed: controller.shareMeeting,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.share, size: 20),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // View summary button
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              final delayedValue = value < 0.25 ? 0.0 : (value - 0.25) / 0.75;
              return Transform.scale(
                scale: delayedValue,
                child: FloatingActionButton.extended(
                  heroTag: 'summary',
                  onPressed: controller.viewFullSummary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.summarize),
                  label: const Text('View Summary'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}