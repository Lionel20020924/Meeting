import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'meetings_controller.dart';

class MeetingsView extends GetView<MeetingsController> {
  const MeetingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('My Meetings'),
            Obx(
              () => Text(
                '${controller.meetings.length} meetings',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: controller.showSearchDialog,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshMeetings,
        child: Obx(
          () {
            if (controller.isLoading.value && controller.meetings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (controller.meetings.isEmpty) {
              return Column(
                children: [
                  // Large empty space for future text display
                  const Expanded(
                    flex: 3,
                    child: SizedBox(),
                  ),
                  // Small icon and text at the bottom third
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No meetings yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap below to start recording',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Compact recording button at the bottom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 16, 48, 32),
                    child: ElevatedButton.icon(
                      onPressed: controller.startRecording,
                      icon: const Icon(Icons.mic, size: 20),
                      label: const Text('Start Recording'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.meetings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final meeting = controller.meetings[index];
                final dateString = meeting['date']?.toString() ?? '';
                final isToday = controller.isToday(dateString);
                
                // Format date for display
                String formattedDate = '';
                try {
                  final date = DateTime.parse(dateString);
                  formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                } catch (e) {
                  formattedDate = dateString;
                }
                
                return Card(
                  child: InkWell(
                    onTap: () => controller.goToMeetingDetail(meeting),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.meeting_room,
                              color: isToday ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meeting['title']?.toString() ?? 'Untitled Meeting',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        formattedDate,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      meeting['duration']?.toString() ?? '00:00',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.people_outline,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${meeting['participants'] ?? '1'} people',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                    ),
                                  ],
                                ),
                                if (isToday) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}