import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'post_recording_controller.dart';

class PostRecordingView extends GetView<PostRecordingController> {
  const PostRecordingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(context),
          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Custom app bar
                _buildCustomAppBar(context),
                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Success animation
                        _buildSuccessAnimation(context),
                        const SizedBox(height: 32),
                        // Meeting info card with edit capability
                        _buildMeetingInfoCard(context),
                        const SizedBox(height: 24),
                        // Quick actions
                        _buildQuickActions(context),
                        const SizedBox(height: 32),
                        // Main action cards
                        _buildActionCards(context),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom action buttons
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1 * value),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05 * value),
                Theme.of(context).colorScheme.surface,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Recording Complete',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildSuccessAnimation(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3 * value),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 300)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    builder: (context, iconValue, child) {
                      return Icon(
                        Icons.check_rounded,
                        size: 60,
                        color: Colors.white.withOpacity(iconValue),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeetingInfoCard(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 400)),
      builder: (context, snapshot) {
        final shouldAnimate = snapshot.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: shouldAnimate ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Card(
                  elevation: 8,
                  shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.95),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Editable title
                        Obx(() => controller.isEditingTitle.value
                            ? TextField(
                                controller: controller.titleController,
                                autofocus: true,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => controller.saveTitle(),
                              )
                            : InkWell(
                                onTap: controller.startEditingTitle,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          controller.meetingData['title'] ?? 'Untitled Meeting',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
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
                        const SizedBox(height: 16),
                        // Meeting metadata
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetadataItem(
                                context,
                                Icons.timer,
                                'Duration',
                                controller.meetingData['duration'] ?? '00:00',
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                              _buildMetadataItem(
                                context,
                                Icons.calendar_today,
                                'Date',
                                _formatDate(DateTime.now()),
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                              _buildMetadataItem(
                                context,
                                Icons.folder,
                                'Size',
                                controller.getFileSize(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetadataItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 600)),
      builder: (context, snapshot) {
        final shouldAnimate = snapshot.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: shouldAnimate ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(
                      context,
                      Icons.play_circle_outline,
                      'Preview',
                      controller.playPreview,
                    ),
                    _buildQuickActionButton(
                      context,
                      Icons.share_outlined,
                      'Share',
                      controller.shareRecording,
                    ),
                    _buildQuickActionButton(
                      context,
                      Icons.label_outline,
                      'Add Tags',
                      controller.addTags,
                    ),
                    _buildQuickActionButton(
                      context,
                      Icons.info_outline,
                      'Details',
                      controller.viewMeetingDetails,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: Future.delayed(const Duration(milliseconds: 800)),
          builder: (context, snapshot) {
            final shouldAnimate = snapshot.connectionState == ConnectionState.done;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: shouldAnimate ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildActionCard(
                      context,
                      icon: Icons.auto_awesome,
                      title: 'Generate AI Summary',
                      subtitle: 'Get insights, action items, and key points',
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      onTap: controller.generateSummaryAndSave,
                      isRecommended: true,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder(
          future: Future.delayed(const Duration(milliseconds: 1000)),
          builder: (context, snapshot) {
            final shouldAnimate = snapshot.connectionState == ConnectionState.done;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: shouldAnimate ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildActionCard(
                      context,
                      icon: Icons.save_alt,
                      title: 'Save Without Summary',
                      subtitle: 'Save the recording and generate summary later',
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ],
                      ),
                      onTap: controller.saveWithoutSummary,
                      isRecommended: false,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    required bool isRecommended,
  }) {
    return Material(
      elevation: isRecommended ? 8 : 4,
      shadowColor: isRecommended
          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
          : Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isRecommended
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isRecommended
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(() => OutlinedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.discardRecording,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: Colors.red.shade400,
                    width: 2,
                  ),
                ),
                child: Text(
                  'Discard',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isGeneratingSummary.value
                    ? null
                    : controller.generateSummaryAndSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: controller.isGeneratingSummary.value
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Processing...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome),
                          const SizedBox(width: 8),
                          const Text(
                            'Generate Summary',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}