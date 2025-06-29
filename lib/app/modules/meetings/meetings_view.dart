import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'meetings_controller.dart';

class MeetingsView extends GetView<MeetingsController> {
  const MeetingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => PopScope(
      canPop: controller.searchQuery.value.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && controller.searchQuery.value.isNotEmpty) {
          controller.clearSearch();
        }
      },
      child: Scaffold(
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
                    Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
            // Main content
            CustomScrollView(
              slivers: [
                // Modern App Bar with Search
                _buildSliverAppBar(context),
                // Filter chips
                _buildFilterChips(context),
                // Statistics Dashboard
                _buildStatisticsDashboard(context),
                // Meetings List
                _buildMeetingsList(context),
              ],
            ),
            // Floating Action Button
            _buildFloatingActionButton(context),
          ],
        ),
      ),
    ));
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return Obx(() => SliverAppBar(
      expandedHeight: controller.isSelectionMode.value ? 60 : 160,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: controller.isSelectionMode.value
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.toggleSelectionMode,
            )
          : controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: controller.clearSearch,
                  tooltip: 'Clear search',
                )
              : null,
      title: controller.isSelectionMode.value
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${controller.selectedMeetings.length} selected',
                  style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${controller.meetings.length} total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : null,
      actions: controller.isSelectionMode.value
          ? _buildSelectionActions(context)
          : _buildNormalActions(context),
      flexibleSpace: FlexibleSpaceBar(
        background: controller.isSelectionMode.value
            ? null
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(() => Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      controller.searchQuery.value.isEmpty
                                          ? 'My Meetings'
                                          : 'Search Results',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: constraints.maxWidth < 350 ? 24 : null,
                                      ),
                                    ),
                                  ),
                                  if (controller.searchQuery.value.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${controller.filteredMeetings.length} found',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                ],
                              )),
                              const SizedBox(height: 12),
                              // Search bar
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Obx(() => TextField(
                                  controller: controller.searchController,
                                  focusNode: controller.searchFocusNode,
                                  onChanged: controller.searchMeetings,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Search meetings...',
                                    hintStyle: const TextStyle(fontSize: 14),
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    suffixIcon: controller.searchQuery.value.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: controller.clearSearch,
                                            tooltip: 'Clear search',
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ));
  }

  List<Widget> _buildSelectionActions(BuildContext context) {
    return [
      // Select all/none button
      IconButton(
        onPressed: () {
          if (controller.selectedMeetings.length == controller.filteredMeetings.length) {
            controller.deselectAll();
          } else {
            controller.selectAll();
          }
        },
        icon: Icon(
          controller.selectedMeetings.length == controller.filteredMeetings.length
              ? Icons.check_box
              : Icons.check_box_outline_blank,
        ),
        tooltip: controller.selectedMeetings.length == controller.filteredMeetings.length
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
    ];
  }

  List<Widget> _buildNormalActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.sort),
        onPressed: () => _showSortOptions(context),
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
    ];
  }

  Widget _buildFilterChips(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() => controller.isSelectionMode.value
          ? const SizedBox.shrink()
          : Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    context,
                    'All',
                    controller.currentFilter.value == 'all',
                    () => controller.setFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    'Today',
                    controller.currentFilter.value == 'today',
                    () => controller.setFilter('today'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    'This Week',
                    controller.currentFilter.value == 'week',
                    () => controller.setFilter('week'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    'This Month',
                    controller.currentFilter.value == 'month',
                    () => controller.setFilter('month'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildStatisticsDashboard(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.isSelectionMode.value || controller.meetings.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meeting Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Icon(
                    Icons.insights,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 380;
                  if (isSmallScreen) {
                    // 小屏幕使用垂直布局
                    return Column(
                      children: [
                        _buildStatCard(
                          context,
                          'Total Meetings',
                          controller.meetings.length.toString(),
                          Icons.meeting_room,
                          Theme.of(context).colorScheme.primary,
                          isCompact: true,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'This Week',
                                controller.getWeeklyMeetingsCount().toString(),
                                Icons.calendar_today,
                                Theme.of(context).colorScheme.secondary,
                                isCompact: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Total Hours',
                                controller.getTotalHours(),
                                Icons.timer,
                                Theme.of(context).colorScheme.tertiary,
                                isCompact: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // 大屏幕使用水平布局
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Meetings',
                            controller.meetings.length.toString(),
                            Icons.meeting_room,
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'This Week',
                            controller.getWeeklyMeetingsCount().toString(),
                            Icons.calendar_today,
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Hours',
                            controller.getTotalHours(),
                            Icons.timer,
                            Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.9)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isCompact ? 20 : 24),
          SizedBox(height: isCompact ? 4 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.meetings.isEmpty) {
        return SliverFillRemaining(
          child: _buildLoadingState(context),
        );
      }

      if (controller.filteredMeetings.isEmpty) {
        return SliverFillRemaining(
          child: _buildEmptyState(context),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildMeetingCard(context, controller.filteredMeetings[index]),
              );
            },
            childCount: controller.filteredMeetings.length,
          ),
        ),
      );
    });
  }

  Widget _buildMeetingCard(BuildContext context, Map<String, dynamic> meeting) {
    final dateString = meeting['date']?.toString() ?? '';
    final isToday = controller.isToday(dateString);
    final relativeTime = controller.getRelativeTime(dateString);
    final meetingId = meeting['id'].toString();
    final isSelected = controller.selectedMeetings.contains(meetingId);

    return Obx(() => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(meetingId),
        direction: controller.isSelectionMode.value
            ? DismissDirection.none
            : DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // Call delete and wait for completion
          await controller.deleteMeeting(meeting);
          // Return false to prevent automatic dismissal since we handle it in the controller
          return false;
        },
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.delete_sweep,
            color: Colors.white,
            size: 30,
          ),
        ),
        child: Material(
          elevation: controller.isSelectionMode.value && isSelected ? 8 : 4,
          shadowColor: isToday
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: controller.isSelectionMode.value && isSelected
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                border: Border.all(
                  color: controller.isSelectionMode.value && isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactCard = constraints.maxWidth < 320;
                  return Padding(
                    padding: EdgeInsets.all(isCompactCard ? 12 : 16),
                    child: Row(
                      children: [
                        // Selection indicator or meeting icon
                        if (controller.isSelectionMode.value)
                          _buildSelectionIndicator(context, isSelected)
                        else
                          _buildMeetingIcon(context, isToday, isCompact: isCompactCard),
                        SizedBox(width: isCompactCard ? 12 : 16),
                        // Meeting details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      meeting['title']?.toString() ?? 'Untitled Meeting',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Meeting metadata - 响应式布局
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isVerySmallScreen = constraints.maxWidth < 280;
                                  return Wrap(
                                spacing: isVerySmallScreen ? 8 : 12,
                                runSpacing: 4,
                                children: [
                                  _buildMetadataChip(
                                    context,
                                    Icons.access_time,
                                    relativeTime,
                                    isCompact: isVerySmallScreen,
                                  ),
                                  _buildMetadataChip(
                                    context,
                                    Icons.timer_outlined,
                                    meeting['duration']?.toString() ?? '00:00',
                                    isCompact: isVerySmallScreen,
                                  ),
                                  _buildMetadataChip(
                                    context,
                                    Icons.people_outline,
                                    '${meeting['participants'] ?? '1'}',
                                    isCompact: isVerySmallScreen,
                                  ),
                                ],
                                  );
                                },
                              ),
                          // Summary and transcription status
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Summary status
                              if (meeting['summary'] != null && meeting['summary'].toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.summarize,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Summary',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Transcription status
                              if (meeting['transcription'] != null && meeting['transcription'].toString().isNotEmpty) ...[
                                if (meeting['summary'] != null && meeting['summary'].toString().isNotEmpty)
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.text_snippet_outlined,
                                          size: 14,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            meeting['transcription'].toString(),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action button
                    if (!controller.isSelectionMode.value)
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios, size: isCompactCard ? 14 : 16),
                        onPressed: () => controller.goToMeetingDetail(meeting),
                        constraints: BoxConstraints(
                          minWidth: isCompactCard ? 32 : 40,
                          minHeight: isCompactCard ? 32 : 40,
                        ),
                        padding: EdgeInsets.all(isCompactCard ? 4 : 8),
                      ),
                  ],
                ),
              );
            },
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildSelectionIndicator(BuildContext context, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildMeetingIcon(BuildContext context, bool isToday, {bool isCompact = false}) {
    final size = isCompact ? 48.0 : 56.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isToday
              ? [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ]
              : [
                  Colors.grey.shade300,
                  Colors.grey.shade400,
                ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.meeting_room_rounded,
        color: isToday ? Colors.white : Colors.grey.shade600,
        size: isCompact ? 24 : 28,
      ),
    );
  }

  Widget _buildMetadataChip(BuildContext context, IconData icon, String label, {bool isCompact = false}) {
    return Container(
      constraints: BoxConstraints(maxWidth: isCompact ? 100 : double.infinity),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: isCompact ? 2 : 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: isCompact ? 11 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * math.pi,
                child: child,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading meetings...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isSearching = controller.searchQuery.value.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
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
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                      ),
                    ),
                    child: Icon(
                      isSearching ? Icons.search_off : Icons.meeting_room_outlined,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? 'No meetings found' : 'No meetings yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSearching 
                  ? 'Try adjusting your search or filters'
                  : 'Start recording your first meeting',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: controller.clearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Obx(() => AnimatedScale(
        scale: controller.isSelectionMode.value ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: () => Get.toNamed('/record'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add),
        ),
      )),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => Column(
              children: [
                _buildSortOption(
                  context,
                  'Date (Newest first)',
                  'date_desc',
                  controller.currentSort.value == 'date_desc',
                ),
                _buildSortOption(
                  context,
                  'Date (Oldest first)',
                  'date_asc',
                  controller.currentSort.value == 'date_asc',
                ),
                _buildSortOption(
                  context,
                  'Title (A-Z)',
                  'title_asc',
                  controller.currentSort.value == 'title_asc',
                ),
                _buildSortOption(
                  context,
                  'Duration (Longest first)',
                  'duration_desc',
                  controller.currentSort.value == 'duration_desc',
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, String label, String value, bool isSelected) {
    return ListTile(
      title: Text(label),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: () {
        controller.setSortOrder(value);
        Navigator.pop(context);
      },
    );
  }
}