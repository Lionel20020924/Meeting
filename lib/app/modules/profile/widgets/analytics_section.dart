import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../profile_controller.dart';

class AnalyticsSection extends GetView<ProfileController> {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: 'analytics',
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          final isCompact = constraints.maxWidth < 380;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meeting Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Analytics Cards Grid with animations
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isCompact ? 1.3 : 1.5,
                  children: [
                    _AnimatedAnalyticsCard(
                      delay: 0,
                      child: _buildAnalyticsCard(
                        context,
                        title: 'Total Recorded',
                        value: controller.totalMeetings.value.toString(),
                        subtitle: 'meetings',
                        icon: Icons.mic_none,
                        color: Theme.of(context).colorScheme.primary,
                        trend: '+12%',
                      ),
                    ),
                    _AnimatedAnalyticsCard(
                      delay: 100,
                      child: _buildAnalyticsCard(
                        context,
                        title: 'This Month',
                        value: controller.monthlyMeetings.value.toString(),
                        subtitle: 'meetings',
                        icon: Icons.calendar_month,
                        color: Colors.green,
                        trend: '+8%',
                      ),
                    ),
                    _AnimatedAnalyticsCard(
                      delay: 200,
                      child: _buildAnalyticsCard(
                        context,
                        title: 'Total Hours',
                        value: _formatTotalHours(
                          controller.averageDuration.value * controller.totalMeetings.value,
                        ),
                        subtitle: 'recorded',
                        icon: Icons.schedule,
                        color: Colors.orange,
                      ),
                    ),
                    if (crossAxisCount == 2) // Show on next row for 2-column layout
                      _AnimatedAnalyticsCard(
                        delay: 300,
                        child: _buildAnalyticsCard(
                          context,
                          title: 'Avg Length',
                          value: controller.formatDuration(controller.averageDuration.value),
                          subtitle: 'per meeting',
                          icon: Icons.timer_outlined,
                          color: Colors.purple,
                        ),
                      ),
                  ],
                ),
                if (crossAxisCount == 3) // Show in same row for 3-column layout
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: isCompact ? 100 : 110,
                      child: _AnimatedAnalyticsCard(
                        delay: 300,
                        child: _buildAnalyticsCard(
                          context,
                          title: 'Avg Length',
                          value: controller.formatDuration(controller.averageDuration.value),
                          subtitle: 'per meeting',
                          icon: Icons.timer_outlined,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Meeting Insights
                _AnimatedAnalyticsCard(
                  delay: 400,
                  child: _buildInsightsCard(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Add tap feedback
          Get.snackbar(
            title,
            'View detailed analytics',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
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
                  if (trend != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 12,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  trend,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(
                        begin: 0,
                        end: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                      ),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, animatedValue, child) {
                        return Text(
                          value.contains('h') || value.contains('m') 
                            ? value 
                            : animatedValue.toString(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Meeting Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            'Most productive day',
            'Thursday',
            Icons.today,
            context,
          ),
          const SizedBox(height: 8),
          _buildInsightRow(
            'Average participants',
            '4-5 people',
            Icons.group,
            context,
          ),
          const SizedBox(height: 8),
          _buildInsightRow(
            'Peak meeting time',
            '10:00 AM - 11:00 AM',
            Icons.access_time,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon, BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

// Animated wrapper for cards
class _AnimatedAnalyticsCard extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimatedAnalyticsCard({
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }
}