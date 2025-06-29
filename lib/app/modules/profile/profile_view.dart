import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Minimalist App Bar
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle pattern overlay
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MinimalPatternPainter(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        size: Size.infinite,
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            // Minimalist Avatar
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.mic_rounded,
                                  size: 42,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // User Display
                            const Text(
                              'Meeting Professional',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Premium User',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Minimalist Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMinimalStat(
                                  value: controller.totalMeetings.value.toString(),
                                  label: 'Meetings',
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                ),
                                _buildMinimalStat(
                                  value: _formatTotalHours(controller.averageDuration.value * controller.totalMeetings.value),
                                  label: 'Total Time',
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                ),
                                _buildMinimalStat(
                                  value: controller.weeklyMeetings.value.toString(),
                                  label: 'This Week',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Get.snackbar(
                    'Settings',
                    'Coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
                icon: Icon(
                  Icons.settings_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                tooltip: 'Settings',
              ),
            ],
          ),
          // Body Content
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Column(
                children: [
                    // Analytics Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Minimalist Analytics Cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.6,
                            children: [
                              _buildMinimalAnalyticsCard(
                                context,
                                title: 'Total Meetings',
                                value: controller.totalMeetings.value.toString(),
                                icon: Icons.videocam_rounded,
                                gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                              ),
                              _buildMinimalAnalyticsCard(
                                context,
                                title: 'This Month',
                                value: controller.monthlyMeetings.value.toString(),
                                icon: Icons.calendar_today_rounded,
                                gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
                              ),
                              _buildMinimalAnalyticsCard(
                                context,
                                title: 'Total Hours',
                                value: _formatTotalHours(controller.averageDuration.value * controller.totalMeetings.value),
                                icon: Icons.schedule_rounded,
                                gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                              ),
                              _buildMinimalAnalyticsCard(
                                context,
                                title: 'Avg Duration',
                                value: controller.formatDuration(controller.averageDuration.value),
                                icon: Icons.timer_rounded,
                                gradient: [const Color(0xFFEC4899), const Color(0xFFF472B6)],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Insights Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.insights_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Insights',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildMinimalInsightRow(
                                  'Most productive',
                                  'Thursday',
                                  context,
                                ),
                                const SizedBox(height: 12),
                                _buildMinimalInsightRow(
                                  'Avg participants',
                                  '4-5 people',
                                  context,
                                ),
                                const SizedBox(height: 12),
                                _buildMinimalInsightRow(
                                  'Peak time',
                                  '10:00 - 11:00 AM',
                                  context,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Settings Sections
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recording Preferences
                            Text(
                              'Recording Preferences',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildMinimalSettingTile(
                                    context,
                                    title: 'Audio Quality',
                                    value: 'High Quality',
                                    onTap: () {},
                                  ),
                                  Container(
                                    height: 0.5,
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  ),
                                  _buildMinimalSettingTile(
                                    context,
                                    title: 'Language',
                                    value: '中文',
                                    onTap: () {},
                                  ),
                                  Container(
                                    height: 0.5,
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  ),
                                  Obx(() => _buildMinimalSwitchTile(
                                    context,
                                    title: 'Auto Backup',
                                    value: true,
                                    onChanged: controller.isEditing.value ? null : (value) {
                                      Get.snackbar(
                                        'Cloud Backup',
                                        'Coming soon',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        margin: const EdgeInsets.all(16),
                                        borderRadius: 12,
                                      );
                                    },
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // AI Settings
                            Text(
                              'AI Assistant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Obx(() => _buildMinimalDropdownTile<int>(
                                    context,
                                    title: 'Default Duration',
                                    value: controller.profileData['meetingPreferences']?['defaultDuration'] ?? 30,
                                    items: const [
                                      DropdownMenuItem(value: 15, child: Text('15 min')),
                                      DropdownMenuItem(value: 30, child: Text('30 min')),
                                      DropdownMenuItem(value: 45, child: Text('45 min')),
                                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                                    ],
                                    onChanged: controller.isEditing.value ? null : (value) {
                                      if (value != null) {
                                        controller.updatePreference('defaultDuration', value);
                                      }
                                    },
                                  )),
                                  Container(
                                    height: 0.5,
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  ),
                                  Obx(() => _buildMinimalSwitchTile(
                                    context,
                                    title: 'Smart Transcription',
                                    value: controller.profileData['meetingPreferences']?['autoTranscribe'] ?? true,
                                    onChanged: controller.isEditing.value ? null : (value) {
                                      controller.updatePreference('autoTranscribe', value);
                                    },
                                  )),
                                  Container(
                                    height: 0.5,
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  ),
                                  Obx(() => _buildMinimalSwitchTile(
                                    context,
                                    title: 'Auto Summary',
                                    value: controller.profileData['meetingPreferences']?['autoSummarize'] ?? true,
                                    onChanged: controller.isEditing.value ? null : (value) {
                                      controller.updatePreference('autoSummarize', value);
                                    },
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Premium Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Upgrade to Pro',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Unlock unlimited features',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _showDataManagementDialog(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(
                                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Manage Data'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: controller.logout,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(
                                        color: Colors.red.withValues(alpha: 0.5),
                                      ),
                                      foregroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Sign Out'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // App Info
                            Center(
                              child: Text(
                                'Version 1.0.0',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
            }),
          ),
        ],
      ),
    );
  }


  // Minimal stat widget for header
  Widget _buildMinimalStat({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }


  // Minimal analytics card
  Widget _buildMinimalAnalyticsCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.map((c) => c.withValues(alpha: 0.9)).toList(),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Minimal insight row
  Widget _buildMinimalInsightRow(
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Minimal setting tile
  Widget _buildMinimalSettingTile(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Minimal switch tile
  Widget _buildMinimalSwitchTile(
    BuildContext context, {
    required String title,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // Minimal dropdown tile
  Widget _buildMinimalDropdownTile<T>(
    BuildContext context, {
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            isDense: true,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Format total hours helper
  String _formatTotalHours(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Show data management dialog
  void _showDataManagementDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _buildDataOption(
                context,
                icon: Icons.download_rounded,
                title: 'Export Data',
                subtitle: 'Download all meetings',
                onTap: () {
                  Get.back();
                  Get.snackbar(
                    'Export',
                    'Coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildDataOption(
                context,
                icon: Icons.cloud_upload_rounded,
                title: 'Cloud Backup',
                subtitle: 'Save to cloud storage',
                onTap: () {
                  Get.back();
                  Get.snackbar(
                    'Backup',
                    'Coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildDataOption(
                context,
                icon: Icons.delete_rounded,
                title: 'Clear Data',
                subtitle: 'Remove all recordings',
                color: Colors.red,
                onTap: () {
                  Get.back();
                  _confirmClearData(context);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: effectiveColor,
                size: 22,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Clear All Data?'),
        content: const Text('This action cannot be undone. All your meetings and recordings will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Data Cleared',
                'All data has been removed',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Minimal pattern painter
class _MinimalPatternPainter extends CustomPainter {
  final Color color;

  _MinimalPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw subtle dots pattern
    const double spacing = 30;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}