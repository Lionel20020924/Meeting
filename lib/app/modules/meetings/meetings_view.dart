import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'meetings_controller.dart';

class MeetingsView extends GetView<MeetingsController> {
  const MeetingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => AppBar(
        leading: controller.isSelectionMode.value
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: controller.toggleSelectionMode,
              )
            : null,
        title: controller.isSelectionMode.value
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${controller.selectedMeetings.length} selected'),
                  Text(
                    '${controller.meetings.length} total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : Column(
                children: [
                  const Text('My Meetings'),
                  Text(
                    '${controller.meetings.length} meetings',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
        actions: controller.isSelectionMode.value
            ? [
                // Select all/none button
                IconButton(
                  onPressed: () {
                    if (controller.selectedMeetings.length == controller.meetings.length) {
                      controller.deselectAll();
                    } else {
                      controller.selectAll();
                    }
                  },
                  icon: Icon(
                    controller.selectedMeetings.length == controller.meetings.length
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  tooltip: controller.selectedMeetings.length == controller.meetings.length
                      ? 'Deselect all'
                      : 'Select all',
                ),
                // Delete button
                IconButton(
                  onPressed: controller.selectedMeetings.isEmpty
                      ? null
                      : controller.deleteSelectedMeetings,
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ]
            : [
                IconButton(
                  onPressed: controller.showSearchDialog,
                  icon: const Icon(Icons.search),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      controller.logout();
                    } else if (value == 'settings') {
                      controller.goToSettings();
                    } else if (value == 'select') {
                      controller.toggleSelectionMode();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.checklist, size: 20),
                          SizedBox(width: 8),
                          Text('Select'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20),
                          SizedBox(width: 8),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ))),
      body: RefreshIndicator(
        onRefresh: controller.refreshMeetings,
        child: Obx(
          () {
            if (controller.isLoading.value && controller.meetings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (controller.meetings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No meetings yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start recording from the bottom navigation',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ],
                ),
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
                
                final meetingId = meeting['id'].toString();
                final isSelected = controller.selectedMeetings.contains(meetingId);
                
                return Obx(() => Dismissible(
                  key: Key(meetingId),
                  direction: controller.isSelectionMode.value 
                      ? DismissDirection.none 
                      : DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    // Return false to prevent automatic dismissal
                    // The controller will handle the deletion and UI update
                    controller.deleteMeeting(meeting);
                    return false;
                  },
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  child: Card(
                    color: controller.isSelectionMode.value && isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                    child: InkWell(
                      onTap: () {
                        if (controller.isSelectionMode.value) {
                          controller.toggleMeetingSelection(meetingId);
                        } else {
                          controller.goToMeetingDetail(meeting);
                        }
                      },
                      onLongPress: () {
                        if (!controller.isSelectionMode.value) {
                          controller.toggleSelectionMode();
                          controller.toggleMeetingSelection(meetingId);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (controller.isSelectionMode.value)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected 
                                          ? Theme.of(context).primaryColor 
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                    color: isSelected 
                                        ? Theme.of(context).primaryColor 
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
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
                            if (!controller.isSelectionMode.value)
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    controller.deleteMeeting(meeting);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ));
              },
            );
          },
        ),
      ),
    );
  }
}