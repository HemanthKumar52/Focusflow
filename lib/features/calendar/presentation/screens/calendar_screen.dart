import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_tab_bar.dart';
import '../../../todo/providers/todo_provider.dart';
import '../../../tasks/providers/task_provider.dart';
import '../../providers/calendar_provider.dart';
import '../widgets/day_view_widget.dart';
import '../widgets/week_view_widget.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedView = ref.watch(calendarViewProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final allEvents = ref.watch(calendarEventsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
              child: Row(
                children: [
                  Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: AppSizes.heading2,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  NeuIconButton(
                    icon: CupertinoIcons.today,
                    tooltip: 'Today',
                    onPressed: () {
                      final now = DateTime.now();
                      ref.read(selectedDateProvider.notifier).state =
                          DateTime(now.year, now.month, now.day);
                    },
                  ),
                ],
              ),
            ),

            // Tab bar: Day / Week / Month
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: NeuTabBar(
                tabs: const ['Day', 'Week', 'Month'],
                selectedIndex: selectedView,
                onTabChanged: (i) =>
                    ref.read(calendarViewProvider.notifier).state = i,
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // Content
            Expanded(
              child: _buildViewContent(
                  selectedView, selectedDate, allEvents, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  // ---------------------------------------------------------------------------
  // View switching
  // ---------------------------------------------------------------------------

  Widget _buildViewContent(
    int view,
    DateTime selectedDate,
    Map<DateTime, List<CalendarEvent>> allEvents,
    bool isDark,
  ) {
    switch (view) {
      case 0:
        return const DayViewWidget();
      case 1:
        return const WeekViewWidget();
      case 2:
      default:
        return _buildMonthView(selectedDate, allEvents, isDark);
    }
  }

  // ---------------------------------------------------------------------------
  // Month view
  // ---------------------------------------------------------------------------

  Widget _buildMonthView(
    DateTime selectedDate,
    Map<DateTime, List<CalendarEvent>> allEvents,
    bool isDark,
  ) {
    final eventsForDay = ref.watch(eventsForSelectedDateProvider);

    return Column(
      children: [
        // TableCalendar
        NeuContainer(
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          padding: const EdgeInsets.only(
              left: AppSizes.sm,
              right: AppSizes.sm,
              top: AppSizes.xs,
              bottom: AppSizes.sm),
          child: TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selectedDate,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return allEvents[key] ?? [];
            },
            onDaySelected: (selected, focused) {
              ref.read(selectedDateProvider.notifier).state =
                  DateTime(selected.year, selected.month, selected.day);
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              ref.read(selectedDateProvider.notifier).state = DateTime(
                  focusedDay.year, focusedDay.month, focusedDay.day);
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: AppSizes.heading4,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              leftChevronIcon: Icon(CupertinoIcons.chevron_left,
                  size: AppSizes.iconSm,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              rightChevronIcon: Icon(CupertinoIcons.chevron_right,
                  size: AppSizes.iconSm,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: AppSizes.caption,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              weekendStyle: TextStyle(
                fontSize: AppSizes.caption,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              todayTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              defaultTextStyle: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              weekendTextStyle: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(),
            ),
            calendarBuilders: CalendarBuilders<CalendarEvent>(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildEventDots(events),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // Events header with Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            children: [
              Text(
                'Events',
                style: TextStyle(
                  fontSize: AppSizes.bodyLarge,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              NeuContainer(
                onTap: () => _showAddSheet(),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: AppSizes.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add,
                        size: AppSizes.iconSm, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: AppSizes.bodySmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xs),

        // Events list for selected day
        Expanded(
          child: eventsForDay.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.calendar_badge_plus,
                        size: 48,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'No events on this day',
                        style: TextStyle(
                          fontSize: AppSizes.body,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md),
                  itemCount: eventsForDay.length,
                  itemBuilder: (context, index) =>
                      _buildEventListItem(eventsForDay[index], isDark),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildEventDots(List<CalendarEvent> events) {
    // Show up to 3 unique-type dots
    final seenTypes = <String>{};
    final dots = <Widget>[];
    for (final event in events) {
      if (seenTypes.contains(event.type)) continue;
      seenTypes.add(event.type);
      if (dots.length >= 3) break;
      dots.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: event.color,
        ),
      ));
    }
    return dots;
  }

  // ---------------------------------------------------------------------------
  // Event list item
  // ---------------------------------------------------------------------------

  Widget _buildEventListItem(CalendarEvent event, bool isDark) {
    final priorityLabel = _priorityLabel(event.priorityIndex);
    final priorityColor = _priorityColor(event.priorityIndex);
    final timeStr = _formatTime(event.dateTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: NeuContainer(
        onTap: () => _navigateToDetail(event),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: isDark ? 0.3 : 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                _iconForType(event.type),
                size: AppSizes.iconSm,
                color: event.color,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            // Title + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: AppSizes.body,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Priority badge
            NeuBadge(
              label: priorityLabel,
              color: priorityColor,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FAB
  // ---------------------------------------------------------------------------

  Widget _buildFAB(bool isDark) {
    return NeuContainer(
      onTap: () => _showAddSheet(),
      width: 56,
      height: 56,
      borderRadius: 28,
      color: AppColors.primary,
      padding: EdgeInsets.zero,
      child: const Center(
        child: Icon(CupertinoIcons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _showAddSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.read(selectedDateProvider);
    final titleController = TextEditingController();
    int selectedType = 0; // 0=Todo, 1=Task, 2=Note
    TaskPriority selectedPriority = TaskPriority.normal;

    NeuBottomSheet.show(
      context: context,
      title: 'Add Event',
      maxHeightFraction: 0.75,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSizes.md,
              right: AppSizes.md,
              top: AppSizes.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date display
                  NeuContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.sm),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar,
                            size: AppSizes.iconSm,
                            color: AppColors.primary),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Title field
                  NeuContainer(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: TextField(
                      controller: titleController,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: AppSizes.body,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Event title...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Type selector
                  Text(
                    'Type',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      _buildTypeButton('Todo', CupertinoIcons.checkmark_circle,
                          AppColors.primary, selectedType == 0, () {
                        setSheetState(() => selectedType = 0);
                      }, isDark),
                      const SizedBox(width: AppSizes.sm),
                      _buildTypeButton('Task', CupertinoIcons.square_stack,
                          AppColors.info, selectedType == 1, () {
                        setSheetState(() => selectedType = 1);
                      }, isDark),
                      const SizedBox(width: AppSizes.sm),
                      _buildTypeButton('Note', CupertinoIcons.doc_text,
                          AppColors.secondary, selectedType == 2, () {
                        setSheetState(() => selectedType = 2);
                      }, isDark),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Priority selector (for Todo and Task only)
                  if (selectedType != 2) ...[
                    Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: AppSizes.bodySmall,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: TaskPriority.values.map((p) {
                        final isSelected = selectedPriority == p;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: p != TaskPriority.low ? AppSizes.xs : 0),
                            child: NeuContainer(
                              onTap: () {
                                setSheetState(() => selectedPriority = p);
                              },
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.sm),
                              color: isSelected
                                  ? p.color.withValues(alpha: 0.15)
                                  : null,
                              child: Center(
                                child: Text(
                                  p.label,
                                  style: TextStyle(
                                    fontSize: AppSizes.caption,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? p.color
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: NeuContainer(
                      onTap: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;
                        _createEvent(
                            title, selectedType, selectedPriority, selectedDate);
                        Navigator.pop(context);
                      },
                      color: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                      child: const Center(
                        child: Text(
                          'Create',
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _createEvent(
      String title, int type, TaskPriority priority, DateTime date) {
    switch (type) {
      case 0: // Todo
        ref.read(todoProvider.notifier).addTodo(
              title,
              dueDate: date,
              priority: priority,
            );
        break;
      case 1: // Task
        ref.read(taskProvider.notifier).addTask(
              title,
              dueDate: date,
              priority: priority,
            );
        break;
      case 2: // Note — create as a todo with normal priority (note-like)
        ref.read(todoProvider.notifier).addTodo(
              title,
              dueDate: date,
              priority: TaskPriority.normal,
              tags: ['note'],
            );
        break;
    }
  }

  Widget _buildTypeButton(String label, IconData icon, Color color,
      bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: NeuContainer(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm, vertical: AppSizes.sm),
        color: isSelected ? color.withValues(alpha: 0.15) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: AppSizes.iconMd,
                color: isSelected
                    ? color
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)),
            const SizedBox(height: AppSizes.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.caption,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _navigateToDetail(CalendarEvent event) {
    switch (event.type) {
      case 'todo':
        context.push('/todos/${event.id}');
        break;
      case 'task':
        context.push('/tasks/${event.id}');
        break;
      case 'study':
        context.push('/study/timer');
        break;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'todo':
        return CupertinoIcons.checkmark_circle;
      case 'task':
        return CupertinoIcons.square_stack;
      case 'study':
        return CupertinoIcons.book;
      default:
        return CupertinoIcons.circle;
    }
  }

  String _priorityLabel(int index) {
    const labels = ['Urgent', 'High', 'Normal', 'Low'];
    if (index >= 0 && index < labels.length) return labels[index];
    return 'Normal';
  }

  Color _priorityColor(int index) {
    const colors = [
      AppColors.priorityUrgent,
      AppColors.priorityHigh,
      AppColors.priorityNormal,
      AppColors.priorityLow,
    ];
    if (index >= 0 && index < colors.length) return colors[index];
    return AppColors.priorityNormal;
  }

  String _formatTime(DateTime dt) {
    if (dt.hour == 0 && dt.minute == 0) return 'All day';
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    if (hour == 0 || hour == 24) return '12:$minute AM';
    if (hour == 12) return '12:$minute PM';
    if (hour < 12) return '$hour:$minute AM';
    return '${hour - 12}:$minute PM';
  }
}
