import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Meeting-focused Header
          SliverAppBar(
            expandedHeight: 320,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Background Pattern
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _WavePatternPainter(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Professional Avatar with Voice Wave
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Animated voice waves
                              // Static voice wave rings
                              ...List.generate(3, (index) {
                                return Container(
                                  width: 100 + (30 * (index + 1)),
                                  height: 100 + (30 * (index + 1)),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1 - (index * 0.03)
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                );
                              }),
                              // Avatar
                              Container(
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
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.mic,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // User Display
                          Column(
                            children: [
                              const Text(
                                'Meeting Professional',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Premium User',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Meeting Stats Summary
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMiniStat(
                                  icon: Icons.mic,
                                  value: controller.totalMeetings.value.toString(),
                                  label: 'Recorded',
                                ),
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                _buildMiniStat(
                                  icon: Icons.access_time,
                                  value: _formatTotalHours(controller.averageDuration.value * controller.totalMeetings.value),
                                  label: 'Hours',
                                ),
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                _buildMiniStat(
                                  icon: Icons.insights,
                                  value: '${controller.weeklyMeetings.value}',
                                  label: 'This Week',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text('Meeting Profile'),
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
                    // Meeting Analytics Dashboard
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meeting Analytics',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Analytics Cards Grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _buildAnalyticsCard(
                                context,
                                title: 'Total Recorded',
                                value: controller.totalMeetings.value.toString(),
                                subtitle: 'meetings',
                                icon: Icons.mic_none,
                                color: Theme.of(context).colorScheme.primary,
                                trend: '+12%',
                              ),
                              _buildAnalyticsCard(
                                context,
                                title: 'This Month',
                                value: controller.monthlyMeetings.value.toString(),
                                subtitle: 'meetings',
                                icon: Icons.calendar_month,
                                color: Colors.green,
                                trend: '+8%',
                              ),
                              _buildAnalyticsCard(
                                context,
                                title: 'Total Hours',
                                value: _formatTotalHours(controller.averageDuration.value * controller.totalMeetings.value),
                                subtitle: 'recorded',
                                icon: Icons.schedule,
                                color: Colors.orange,
                              ),
                              _buildAnalyticsCard(
                                context,
                                title: 'Avg Length',
                                value: controller.formatDuration(controller.averageDuration.value),
                                subtitle: 'per meeting',
                                icon: Icons.timer_outlined,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Meeting Insights
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
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
                                    const Text(
                                      'Meeting Insights',
                                      style: TextStyle(
                                        fontSize: 16,
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
                                ),
                                const SizedBox(height: 8),
                                _buildInsightRow(
                                  'Average participants',
                                  '4-5 people',
                                  Icons.group,
                                ),
                                const SizedBox(height: 8),
                                _buildInsightRow(
                                  'Peak meeting time',
                                  '10:00 AM - 11:00 AM',
                                  Icons.access_time,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile Sections
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recording Preferences Section
                            _buildSectionTitle('Recording Preferences', Icons.settings_voice),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildPreferenceTile(
                                    context,
                                    icon: Icons.mic_none,
                                    iconColor: Colors.blue,
                                    title: 'Audio Quality',
                                    subtitle: 'Recording quality settings',
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'High Quality',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  _buildPreferenceTile(
                                    context,
                                    icon: Icons.language,
                                    iconColor: Colors.green,
                                    title: 'Transcription Language',
                                    subtitle: 'Primary language for meetings',
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        '中文',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  Obx(() => SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    secondary: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload_outlined,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    title: const Text('Auto Cloud Backup'),
                                    subtitle: const Text('Automatically backup recordings'),
                                    value: true,
                                    onChanged: controller.isEditing.value ? null : (value) {
                                      Get.snackbar(
                                        'Cloud Backup',
                                        'Feature coming soon',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    },
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // AI Assistant Settings
                            _buildSectionTitle('AI Assistant Settings', Icons.auto_awesome),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.timer_outlined,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    title: const Text('Meeting Duration'),
                                    subtitle: const Text('Default length for new meetings'),
                                    trailing: Obx(() => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: DropdownButton<int>(
                                        value: controller.profileData['meetingPreferences']?['defaultDuration'] ?? 30,
                                        underline: const SizedBox(),
                                        isDense: true,
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
                                      ),
                                    )),
                                  ),
                                  const Divider(height: 1),
                                  Obx(() => SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    secondary: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.transcribe_outlined,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    title: const Text('Smart Transcription'),
                                    subtitle: const Text('AI-powered speech recognition'),
                                    value: controller.profileData['meetingPreferences']?['autoTranscribe'] ?? true,
                                    onChanged: controller.isEditing.value ? null : (value) {
                                      controller.updatePreference('autoTranscribe', value);
                                    },
                                  )),
                                  const Divider(height: 1),
                                  Obx(() => SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    secondary: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.summarize_outlined,
                                        color: Colors.green,
                                      ),
                                    ),
                                    title: const Text('Intelligent Summary'),
                                    subtitle: const Text('Generate key insights and action items'),
                                    value: controller.profileData['meetingPreferences']?['autoSummarize'] ?? true,
                                    onChanged: controller.isEditing.value ? null : (value) {
                                      controller.updatePreference('autoSummarize', value);
                                    },
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Premium Features
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade700,
                                    Colors.orange.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.workspace_premium,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Upgrade to Pro',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'Unlock advanced features',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white.withValues(alpha: 0.7),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildProFeature(Icons.all_inclusive, 'Unlimited'),
                                      _buildProFeature(Icons.speed, 'Fast AI'),
                                      _buildProFeature(Icons.cloud_done, 'Cloud Sync'),
                                      _buildProFeature(Icons.support_agent, 'Priority'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showDataManagementDialog(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.folder_outlined),
                                    label: const Text('Manage Data'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: controller.logout,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(
                                        color: Colors.red,
                                      ),
                                      foregroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Sign Out'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // App Version
                            Center(
                              child: Text(
                                'Version 1.0.0',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
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


  // Section title widget
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Get.theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  // Mini stat widget for header
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

  // Analytics card widget
  Widget _buildAnalyticsCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Insight row widget
  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Get.theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Get.theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Preference tile widget
  Widget _buildPreferenceTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }

  // Pro feature widget
  Widget _buildProFeature(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      AlertDialog(
        title: const Text('Data Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export All Data'),
              subtitle: const Text('Download your meetings and summaries'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Export',
                  'Export feature coming soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup to Cloud'),
              subtitle: const Text('Save your data to cloud storage'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Backup',
                  'Cloud backup coming soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Clear All Data'),
              subtitle: const Text('Remove all meetings and recordings'),
              onTap: () {
                Get.back();
                Get.dialog(
                  AlertDialog(
                    title: const Text('Clear All Data?'),
                    content: const Text('This action cannot be undone.'),
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
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Wave pattern painter for background
class _WavePatternPainter extends CustomPainter {
  final Color color;

  _WavePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    
    for (int i = 0; i < 3; i++) {
      final waveHeight = 20.0 + (i * 10);
      final yOffset = 50.0 + (i * 40);
      
      path.moveTo(0, yOffset);
      
      for (double x = 0; x <= size.width; x += 10) {
        final y = yOffset + math.sin((x / size.width) * 2 * math.pi) * waveHeight;
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}