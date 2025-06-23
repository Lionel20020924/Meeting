import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          Obx(() => controller.isEditing.value
              ? Row(
                  children: [
                    TextButton(
                      onPressed: controller.toggleEdit,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: controller.isSaving.value ? null : controller.saveProfile,
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                    const SizedBox(width: 16),
                  ],
                )
              : IconButton(
                  onPressed: controller.toggleEdit,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Profile',
                ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Avatar
                      Obx(() => CircleAvatar(
                        radius: 60,
                        backgroundColor: controller.avatarColor,
                        child: Text(
                          controller.userInitials,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )),
                      const SizedBox(height: 16),
                      // Name and Email
                      Obx(() => Text(
                        controller.userName.isEmpty ? 'Set Your Name' : controller.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        controller.userEmail.isEmpty ? 'Set Your Email' : controller.userEmail,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              // Meeting Statistics
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Meeting Statistics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              'Total',
                              controller.totalMeetings.value.toString(),
                              Icons.video_library,
                              Colors.blue,
                            ),
                            _buildStatItem(
                              context,
                              'This Week',
                              controller.weeklyMeetings.value.toString(),
                              Icons.calendar_today,
                              Colors.green,
                            ),
                            _buildStatItem(
                              context,
                              'This Month',
                              controller.monthlyMeetings.value.toString(),
                              Icons.date_range,
                              Colors.orange,
                            ),
                            _buildStatItem(
                              context,
                              'Avg Duration',
                              controller.formatDuration(controller.averageDuration.value),
                              Icons.timer,
                              Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Profile Form / Display
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      // Personal Information
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Obx(() => controller.isEditing.value
                                  ? Column(
                                      children: [
                                        TextFormField(
                                          controller: controller.nameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Name',
                                            prefixIcon: Icon(Icons.person_outline),
                                          ),
                                          validator: controller.validateName,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: controller.emailController,
                                          decoration: const InputDecoration(
                                            labelText: 'Email',
                                            prefixIcon: Icon(Icons.email_outlined),
                                          ),
                                          keyboardType: TextInputType.emailAddress,
                                          validator: controller.validateEmail,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: controller.phoneController,
                                          decoration: const InputDecoration(
                                            labelText: 'Phone',
                                            prefixIcon: Icon(Icons.phone_outlined),
                                          ),
                                          keyboardType: TextInputType.phone,
                                          validator: controller.validatePhone,
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildInfoRow('Name', controller.profileData['name'] ?? 'Not set'),
                                        _buildInfoRow('Email', controller.profileData['email'] ?? 'Not set'),
                                        _buildInfoRow('Phone', controller.profileData['phone'] ?? 'Not set'),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Professional Information
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.work,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Professional Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Obx(() => controller.isEditing.value
                                  ? Column(
                                      children: [
                                        TextFormField(
                                          controller: controller.companyController,
                                          decoration: const InputDecoration(
                                            labelText: 'Company',
                                            prefixIcon: Icon(Icons.business_outlined),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: controller.positionController,
                                          decoration: const InputDecoration(
                                            labelText: 'Position',
                                            prefixIcon: Icon(Icons.badge_outlined),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: controller.departmentController,
                                          decoration: const InputDecoration(
                                            labelText: 'Department',
                                            prefixIcon: Icon(Icons.group_outlined),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: controller.bioController,
                                          decoration: const InputDecoration(
                                            labelText: 'Bio',
                                            prefixIcon: Icon(Icons.info_outline),
                                            alignLabelWithHint: true,
                                          ),
                                          maxLines: 3,
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildInfoRow('Company', controller.profileData['company'] ?? 'Not set'),
                                        _buildInfoRow('Position', controller.profileData['position'] ?? 'Not set'),
                                        _buildInfoRow('Department', controller.profileData['department'] ?? 'Not set'),
                                        _buildInfoRow('Bio', controller.profileData['bio'] ?? 'Not set', isMultiline: true),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Meeting Preferences
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Meeting Preferences',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.timer_outlined),
                                title: const Text('Default Meeting Duration'),
                                trailing: DropdownButton<int>(
                                  value: controller.profileData['meetingPreferences']?['defaultDuration'] ?? 30,
                                  items: const [
                                    DropdownMenuItem(value: 15, child: Text('15 min')),
                                    DropdownMenuItem(value: 30, child: Text('30 min')),
                                    DropdownMenuItem(value: 45, child: Text('45 min')),
                                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      controller.updatePreference('defaultDuration', value);
                                    }
                                  },
                                ),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: const Icon(Icons.transcribe_outlined),
                                title: const Text('Auto-Transcribe'),
                                subtitle: const Text('Automatically transcribe audio'),
                                value: controller.profileData['meetingPreferences']?['autoTranscribe'] ?? true,
                                onChanged: (value) {
                                  controller.updatePreference('autoTranscribe', value);
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: const Icon(Icons.summarize_outlined),
                                title: const Text('Auto-Summarize'),
                                subtitle: const Text('Generate summary after transcription'),
                                value: controller.profileData['meetingPreferences']?['autoSummarize'] ?? true,
                                onChanged: (value) {
                                  controller.updatePreference('autoSummarize', value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: controller.logout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey[500] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}