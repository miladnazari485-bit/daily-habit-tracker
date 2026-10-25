import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../models/habit.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/page_header.dart';
import '../widgets/sheets.dart';

/// Week view of colored habit and to-do blocks. The month grid stays on this tab.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.onMenu,
    required this.onOpenDay,
  });

  final VoidCallback onMenu;
  final ValueChanged<DateTime> onOpenDay;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _anchor;
  bool _sessionApplied = false;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _anchor = today;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionApplied) return;
    _sessionApplied = true;
    final saved = AppScope.of(context).calendarMonth;
    _anchor = DateTime(saved.year, saved.month, 1);
  }

  /// Moves the colored week forward or back and remembers that month.
  void _shiftWeek(int delta) {
    final next = _anchor.add(Duration(days: 7 * delta));
    setState(() => _anchor = next);
    AppScope.of(context).rememberCalendarMonth(DateTime(next.year, next.month));
  }

  /// Jumps the calendar back to the current week.
  void _jumpToday() {
    final today = dateOnly(DateTime.now());
    setState(() => _anchor = today);
    AppScope.of(context).rememberCalendarMonth(DateTime(today.year, today.month));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final start = startOfWeek(_anchor, weekStart: state.weekStart);
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    final today = dateOnly(DateTime.now());
    const hourHeight = 56.0;
    const gutter = 52.0;

    return Column(
      children: [
        PageHeader(
          title: 'Calendar',
          night: state.night,
          onMenu: widget.onMenu,
          onToggleTheme: state.toggleNight,
          trailing: HeaderIconButton(
            tooltip: 'Calendar options',
            onPressed: () => _more(context),
            child: Icon(Icons.more_horiz_rounded, color: colors.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _MonthChip(label: monthYearLabel(_anchor)),
              ),
              const SizedBox(width: 8),
              _RoundStep(
                tooltip: 'Previous week',
                icon: Icons.chevron_left_rounded,
                onTap: () => _shiftWeek(-1),
              ),
              const SizedBox(width: 8),
              _RoundStep(
                tooltip: 'This week',
                label: 'Today',
                onTap: _jumpToday,
              ),
              const SizedBox(width: 8),
              _RoundStep(
                tooltip: 'Next week',
                icon: Icons.chevron_right_rounded,
                onTap: () => _shiftWeek(1),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: gutter, right: 8),
          child: Row(
            children: [
              for (final day in days)
                Expanded(child: _DayHead(day: day, today: isSameDay(day, today))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final column = (constraints.maxWidth - gutter - 8) / 7;
              final blocks = _blocks(state, days);
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 96),
                child: SizedBox(
                  height: 24 * hourHeight,
                  child: Stack(
                    children: [
                      for (var hour = 0; hour < 24; hour++)
                        Positioned(
                          top: hour * hourHeight,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: hourHeight,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: gutter,
                                  child: Text(
                                    '${hour.toString().padLeft(2, '0')}:00',
                                    style: TextStyle(
                                      color: colors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: colors.line),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final block in blocks)
                        Positioned(
                          left: gutter + block.column * column + 2,
                          width: column - 4,
                          top: (block.minutes / 60) * hourHeight + 4,
                          height: block.height,
                          child: _ColorField(block: block, onTap: () {
                            if (block.habitId != null) {
                              widget.onOpenDay(block.day);
                              return;
                            }
                            widget.onOpenDay(block.day);
                          }),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<_Block> _blocks(AppState state, List<DateTime> days) {
    final blocks = <_Block>[];
    final byDay = {for (final day in days) dateKey(day): days.indexOf(day)};
    if (state.calendarSync) {
      for (final task in state.tasks) {
        final column = byDay[dateKey(task.dueDate)];
        if (column == null) continue;
        blocks.add(
          _Block(
            column: column,
            minutes: task.minutes,
            height: 28,
            color: const Color(0xFFCBC6F6),
            label: task.title,
            day: task.dueDate,
          ),
        );
      }
    }
    for (final habit in state.activeHabits) {
      for (final day in days) {
        if (valueOn(habit, day) <= 0) continue;
        final journalTime = _journalMinutes(state, habit, day);
        blocks.add(
          _Block(
            column: byDay[dateKey(day)]!,
            minutes: journalTime,
            height: 18 + 28 * ratioOn(habit, day),
            color: Color(habit.colorValue),
            label: habit.name,
            day: day,
            habitId: habit.id,
          ),
        );
      }
    }
    return blocks;
  }

  /// Minute of day for a habit block, taken from its journal line when one exists.
  int _journalMinutes(AppState state, Habit habit, DateTime day) {
    for (final entry in state.journal) {
      if (entry.habitId == habit.id && isSameDay(entry.at, day)) {
        return entry.at.hour * 60 + entry.at.minute;
      }
    }
    return 7 * 60 + (habit.name.hashCode.abs() % 180);
  }

  /// Menu for jumping to today or opening the selected day on Today.
  Future<void> _more(BuildContext context) async {
    final colors = AppColors.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Add a to-do'),
                onTap: () => Navigator.pop(context, 'task'),
              ),
              ListTile(
                title: const Text('Jump to today'),
                onTap: () => Navigator.pop(context, 'today'),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'today') {
      _jumpToday();
      return;
    }
    await showComposer(context, kind: ComposerKind.task);
  }
}

class _Block {
  const _Block({
    required this.column,
    required this.minutes,
    required this.height,
    required this.color,
    required this.label,
    required this.day,
    this.habitId,
  });

  final int column;
  final int minutes;
  final double height;
  final Color color;
  final String label;
  final DateTime day;
  final String? habitId;
}

class _ColorField extends StatelessWidget {
  const _ColorField({required this.block, required this.onTap});

  final _Block block;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: block.color,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            block.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundOn(block.color),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHead extends StatelessWidget {
  const _DayHead({required this.day, required this.today});

  final DateTime day;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const letters = ['Su', 'M', 'T', 'W', 'Th', 'F', 'S'];
    return Column(
      children: [
        Text(
          letters[sundayIndex(day)],
          style: TextStyle(
            color: colors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: today ? colors.ink : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: today ? colors.card : colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RoundStep extends StatelessWidget {
  const _RoundStep({
    required this.tooltip,
    required this.onTap,
    this.icon,
    this.label,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final filled = label != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? colors.ink : colors.chip,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: onTap,
          child: SizedBox(
            height: 44,
            width: label == null ? 44 : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
              child: Center(
                child: label == null
                    ? Icon(icon, color: colors.ink)
                    : Text(
                        label!,
                        style: TextStyle(
                          color: colors.card,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
