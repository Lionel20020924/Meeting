import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../profile_controller.dart';

class ProfileHeader extends GetView<ProfileController> {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280, // Reduced from 320
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Simplified gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
              ),
            ),
            // Simplified wave pattern with RepaintBoundary
            RepaintBoundary(
              child: CustomPaint(
                painter: _OptimizedWavePatternPainter(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                size: Size.infinite,
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GetBuilder<ProfileController>(
                  id: 'header',
                  builder: (controller) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Professional Avatar with simple decoration
                      _buildAvatar(context),
                      const SizedBox(height: 20),
                      // User Display
                      _buildUserInfo(context),
                      const SizedBox(height: 16),
                      // Meeting Stats Summary
                      _buildStatsSummary(context, controller),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          'Meeting Profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          onPressed: () {
            Get.snackbar(
              'Settings',
              'Settings page coming soon',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Hero(
      tag: 'profile-avatar',
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.mic,
              size: 48,
              color: Colors.white,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      children: [
        Text(
          'Meeting Professional',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Premium User',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary(BuildContext context, ProfileController controller) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniStat(
                  icon: Icons.mic,
                  value: controller.totalMeetings.value.toString(),
                  label: 'Recorded',
                ),
                _buildDivider(),
                _buildMiniStat(
                  icon: Icons.access_time,
                  value: _formatTotalHours(
                    controller.averageDuration.value * controller.totalMeetings.value,
                  ),
                  label: 'Hours',
                ),
                _buildDivider(),
                _buildMiniStat(
                  icon: Icons.insights,
                  value: '${controller.weeklyMeetings.value}',
                  label: 'This Week',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  String _formatTotalHours(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// Optimized wave pattern painter
class _OptimizedWavePatternPainter extends CustomPainter {
  final Color color;
  final Path _cachedPath = Path();

  _OptimizedWavePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Reduced stroke width

    // Simplified wave pattern
    _cachedPath.reset();
    
    for (int i = 0; i < 2; i++) { // Reduced from 3 to 2 waves
      final waveHeight = 15.0 + (i * 10);
      final yOffset = 60.0 + (i * 50);
      
      _cachedPath.moveTo(0, yOffset);
      
      // Reduced resolution for better performance
      for (double x = 0; x <= size.width; x += 20) {
        final y = yOffset + math.sin((x / size.width) * 2 * math.pi) * waveHeight;
        _cachedPath.lineTo(x, y);
      }
    }
    
    canvas.drawPath(_cachedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}