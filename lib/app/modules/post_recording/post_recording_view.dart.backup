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
            child: Column(
              children: [
                // Custom app bar
                _buildCustomAppBar(context),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Success animation
                        _buildSuccessAnimation(context),
                        const SizedBox(height: 32),
                        // Meeting info card with edit capability
                        _buildMeetingInfoCard(context),
                        const SizedBox(height: 32),
                        // Main action section - simplified
                        _buildMainActions(context),
                        const SizedBox(height: 24),
                        // Secondary actions - moved to expandable section
                        _buildSecondaryActions(context),
                        const SizedBox(height: 100), // Space for bottom actions
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom primary actions - simplified
          _buildBottomPrimaryActions(context),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Recording Complete',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
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
            width: 100,
            height: 100,
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
                  spreadRadius: 3,
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
                        size: 50,
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

  // New simplified main actions - focus on primary choices
  Widget _buildMainActions(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What would you like to do?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Primary action - Generate Summary
                    _buildPrimaryActionCard(
                      context,
                      icon: Icons.auto_awesome,
                      title: 'Generate AI Summary',
                      subtitle: 'Get insights, action items, and key points automatically',
                      onTap: controller.generateSummaryAndSave,
                      isLoading: controller.isGeneratingSummary,
                    ),
                    const SizedBox(height: 12),
                    // Secondary action - Save without summary
                    _buildSecondaryActionCard(
                      context,
                      icon: Icons.save_outlined,
                      title: 'Save Recording Only',
                      subtitle: 'Save now, generate summary later',
                      onTap: controller.saveWithoutSummary,
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

  Widget _buildPrimaryActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required RxBool isLoading,
  }) {
    return Obx(() => Material(
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading.value ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading.value
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 28,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading.value ? 'Processing...' : title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading.value ? 'Generating your meeting summary' : subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLoading.value)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildSecondaryActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New expandable secondary actions
  Widget _buildSecondaryActions(BuildContext context) {
    return FutureBuilder(
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
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                  childrenPadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.more_horiz,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'More Options',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSecondaryActionButton(
                          context,
                          Icons.play_circle_outline,
                          'Preview',
                          controller.playPreview,
                        ),
                        _buildSecondaryActionButton(
                          context,
                          Icons.share_outlined,
                          'Share',
                          controller.shareRecording,
                        ),
                        _buildSecondaryActionButton(
                          context,
                          Icons.label_outline,
                          'Tags',
                          controller.addTags,
                        ),
                        _buildSecondaryActionButton(
                          context,
                          Icons.info_outline,
                          'Details',
                          controller.viewMeetingDetails,
                        ),
                      ],
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

  Widget _buildSecondaryActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simplified bottom actions - only discard
  Widget _buildBottomPrimaryActions(BuildContext context) {
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
        child: Obx(() => OutlinedButton(
          onPressed: controller.isSaving.value ? null : controller.discardRecording,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(
              color: Colors.red.shade400,
              width: 2,
            ),
            foregroundColor: Colors.red.shade400,
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Discard Recording',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )),
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