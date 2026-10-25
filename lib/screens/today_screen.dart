import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_span_grid.dart';
import '../widgets/page_header.dart';
import '../widgets/sheets.dart';
import '../widgets/timer_sheet.dart';

/// First page: one week of days, then to-dos, open habits, and finished habits.
class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.onMenu,
    required this.onOpenStats,
    required this.onOpenHabit,
  });

  final VoidCallback onMenu;
  final VoidCallback onOpenStats;
  final ValueChanged<String> onOpenHabit;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _trackedSelected = dateOnly(DateTime.now());
  AppState? _state;
  bool _sessionApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AppScope.of(context);
    if (!identical(_state, next)) {
      _state?.removeListener(_onState);
      _state = next;
      _state!.addListener(_onState);
    }
    if (!_sessionApplied) {
      _sessionApplied = true;
      _trackedSelected = next.selectedDate;
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_onState);
    super.dispose();
  }

  /// Keeps the remembered month aligned when another page changes the day.
  void _onState() {
    if (!mounted || _state == null) return;
    final selected = _state!.selectedDate;
    if (isSameDay(_trackedSelected, selected)) return;
    _trackedSelected = selected;
    final month = DateTime(selected.year, selected.month);
    if (!isSameMonth(month, _state!.todayMonth)) {
      _state!.rememberTodayMonth(month);
    }
  }

  /// Tells the user a future day cannot be logged yet.
  void _blocked() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You can log a habit once that day arrives.')),
    );
  }

  /// Moves an overdue to-do to today, tomorrow, next week, or a picked day.
  Future<void> _postpone(TaskItem task) async {
    final state = AppScope.of(context);
    final today = dateOnly(DateTime.now());
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Today'),
                onTap: () => Navigator.pop(context, 'today'),
              ),
              ListTile(
                title: const Text('Tomorrow'),
                onTap: () => Navigator.pop(context, 'tomorrow'),
              ),
              ListTile(
                title: const Text('Next week'),
                onTap: () => Navigator.pop(context, 'week'),
              ),
              ListTile(
                title: const Text('Pick a date'),
                onTap: () => Navigator.pop(context, 'pick'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    DateTime? target;
    if (choice == 'today') target = today;
    if (choice == 'tomorrow') target = today.add(const Duration(days: 1));
    if (choice == 'week') target = today.add(const Duration(days: 7));
    if (choice == 'pick') {
      final picked = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked == null || !mounted) return;
      target = dateOnly(picked);
    }
    if (target == null) return;
    state.postponeTask(task.id, target);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final selected = state.selectedDate;
    final today = dateOnly(DateTime.now());
    final habits = state.activeHabits
        .where((habit) => _matches(habit.name, state.boardQuery))
        .toList();
    final openHabits = habits.where((habit) => !isComplete(habit, selected));
    final doneHabits = habits.where((habit) => isComplete(habit, selected));
    final doneCount = doneHabits.length;
    final showTasks = state.todayList != 'habits';
    final showHabits = state.todayList != 'tasks';
    final tasks = _tasksFor(state, selected, today)
        .where((task) => _matches(task.title, state.boardQuery))
        .toList();

    return Column(
      children: [
        PageHeader(
          title: 'Today',
          night: state.night,
          badge: doneCount,
          onMenu: widget.onMenu,
          onToggleTheme: state.toggleNight,
          onChart: widget.onOpenStats,
          trailing: HeaderIconButton(
            tooltip: 'Timer',
            onPressed: () => showTimerSheet(context),
            circular: false,
            child: Icon(Icons.timer_outlined, color: colors.ink, size: 20),
          ),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('today-list'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              _WeekStrip(
                selected: selected,
                weekStart: state.weekStart,
                onSelect: state.selectDate,
              ),
              const SizedBox(height: 16),
              if (showTasks) ...[
                _SectionTitle(
                  icon: Icons.checklist_rounded,
                  title: 'To-Do List',
                  count: tasks.where((task) => !task.done).length,
                  open: state.todosOpen,
                  onTap: () => state.rememberTodosOpen(!state.todosOpen),
                ),
                if (state.todosOpen) ...[
                  const SizedBox(height: 8),
                  if (tasks.isEmpty)
                    _EmptyLine(
                      text: state.todayList == 'tasks'
                          ? 'No to-dos match this view.'
                          : 'Nothing is due on this day.',
                    )
                  else
                    for (final task in tasks)
                      _TodoRow(
                        task: task,
                        today: today,
                        onToggle: () => state.toggleTask(task.id),
                        onPostpone: () => _postpone(task),
                      ),
                ],
                const SizedBox(height: 18),
              ],
              if (showHabits) ...[
                _SectionTitle(
                  icon: Icons.view_list_rounded,
                  title: 'Daily Habits',
                  count: openHabits.length,
                  open: state.habitsOpen,
                  progress: habits.isEmpty ? 0 : doneCount / habits.length,
                  onTap: () => state.rememberHabitsOpen(!state.habitsOpen),
                ),
              if (state.habitsOpen) ...[
                const SizedBox(height: 8),
                if (openHabits.isEmpty)
                  _EmptyLine(
                    text: habits.isEmpty
                        ? 'Add a habit with the + button.'
                        : 'Every habit for this day is in Completed.',
                  )
                else
                  for (final habit in openHabits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HabitTile(
                        habit: habit,
                        selected: selected,
                        today: today,
                        weekStart: state.weekStart,
                        onOpen: () => widget.onOpenHabit(habit.id),
                        onBlocked: _blocked,
                        smartInput: state.smartInput,
                      ),
                    ),
              ],
              const SizedBox(height: 8),
              _SectionTitle(
                icon: Icons.check_circle_outline_rounded,
                title: 'Completed',
                count: doneCount,
                open: state.completedOpen,
                onTap: () => state.rememberCompletedOpen(!state.completedOpen),
              ),
              if (state.completedOpen) ...[
                const SizedBox(height: 8),
                if (doneHabits.isEmpty)
                  const _EmptyLine(text: 'No habit is finished for this day.')
                else
                  for (final habit in doneHabits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HabitTile(
                        habit: habit,
                        selected: selected,
                        today: today,
                        weekStart: state.weekStart,
                        done: true,
                        onOpen: () => widget.onOpenHabit(habit.id),
                        onBlocked: _blocked,
                        smartInput: state.smartInput,
                      ),
                    ),
              ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// True when [name] contains the menu search text.
  bool _matches(String name, String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    return name.toLowerCase().contains(text);
  }

  /// To-dos due on the selected day. Today's list also includes overdue items.
  /// All Tasks ignores the selected day and returns every to-do.
  List<TaskItem> _tasksFor(AppState state, DateTime selected, DateTime today) {
    final viewingToday = isSameDay(selected, today);
    final items = state.tasks.where((task) {
      if (state.todayList == 'tasks') return true;
      if (isSameDay(task.dueDate, selected)) return true;
      return viewingToday && task.isOverdueOn(today);
    }).toList();
    items.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return a.dueDate.compareTo(b.dueDate);
    });
    return items;
  }
}

/// Seven day pills for the week that contains the selected day.
///
/// This stays a single week. The full month grid lives on the Calendar tab,
/// so Today does not grow into a second calendar.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selected,
    required this.weekStart,
    required this.onSelect,
  });

  final DateTime selected;
  final int weekStart;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final start = startOfWeek(selected, weekStart: weekStart);
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _DayPill(
                day: start.add(Duration(days: i)),
                selected: isSameDay(start.add(Duration(days: i)), selected),
                onTap: () => onSelect(start.add(Duration(days: i))),
              ),
            ),
          ),
      ],
    );
  }
}

/// One day in the week strip. The selected day uses the lighter card.
class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final today = isSameDay(day, DateTime.now());
    const letters = ['Su', 'M', 'T', 'W', 'Th', 'F', 'S'];
    return Material(
      color: selected ? colors.card : colors.chip.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                letters[sundayIndex(day)],
                style: TextStyle(
                  color: today ? colors.ink : colors.muted,
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 16,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header that folds its section up or down. Completed uses the chevron.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.count,
    required this.open,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final String title;
  final int count;
  final bool open;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: colors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            if (progress != null)
              _MiniRing(progress: progress!)
            else
              Icon(
                open ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
                color: colors.muted,
              ),
          ],
        ),
      ),
    );
  }
}

/// How many of today's habits are already finished, drawn as a small ring.
class _MiniRing extends StatelessWidget {
  const _MiniRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        value: progress.clamp(0, 1),
        strokeWidth: 3,
        backgroundColor: colors.line,
        color: colors.ink,
      ),
    );
  }
}

/// Short line shown when a section has nothing to list.
class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.of(context).muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One to-do. The row stays one line until it is opened for a comment.
class _TodoRow extends StatefulWidget {
  const _TodoRow({
    required this.task,
    required this.today,
    required this.onToggle,
    required this.onPostpone,
  });

  final TaskItem task;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback onPostpone;

  @override
  State<_TodoRow> createState() => _TodoRowState();
}

class _TodoRowState extends State<_TodoRow> {
  bool _open = false;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.task.note);
  }

  @override
  void didUpdateWidget(_TodoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _open = false;
      _note.text = widget.task.note;
    } else if (oldWidget.task.note != widget.task.note &&
        _note.text.trim() != widget.task.note) {
      _note.text = widget.task.note;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Writes the comment without changing the title or the due day.
  void _saveNote(String value) {
    AppScope.of(context).setTaskNote(widget.task.id, value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final task = widget.task;
    final overdue = task.isOverdueOn(widget.today);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: task.done ? 'Mark not done' : 'Mark done',
                    onPressed: widget.onToggle,
                    icon: Icon(
                      task.done
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: task.done ? colors.ink : colors.muted,
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _open = !_open),
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                          decoration: task.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ),
                  if (task.note.isNotEmpty && !_open)
                    Icon(Icons.chat_bubble_outline_rounded, size: 16, color: colors.muted),
                  if (overdue && !task.done)
                    TextButton(
                      onPressed: widget.onPostpone,
                      child: const Text('Postpone'),
                    ),
                ],
              ),
              if (_open)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),
                  child: TextField(
                    controller: _note,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _saveNote,
                    decoration: const InputDecoration(
                      hintText: 'Comment',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Habit card for the selected day, including that week's seven mini bars.
///
/// A habit whose logged amount has reached its goal is not built here for
/// Daily Habits. The page places those cards in Completed instead.
class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.selected,
    required this.today,
    required this.weekStart,
    required this.onOpen,
    required this.onBlocked,
    required this.smartInput,
    this.done = false,
  });

  final Habit habit;
  final DateTime selected;
  final DateTime today;
  final int weekStart;
  final VoidCallback onOpen;
  final VoidCallback onBlocked;
  final bool smartInput;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final state = AppScope.of(context);
    final value = valueOn(habit, selected);
    final future = dateOnly(selected).isAfter(today);
    final color = Color(habit.colorValue);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Flexible(
                    child: HabitNameChip(name: habit.name, color: color),
                  ),
                  const SizedBox(width: 8),
                  StreakPill(streak: currentStreak(habit, today)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${formatInt(value)} / ${formatInt(habit.goal)} ${habit.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Action(
                    done: done,
                    large: habit.goal > 20,
                    color: color,
                    onTap: () {
                      if (future) {
                        onBlocked();
                        return;
                      }
                      if (done) {
                        state.setHabitValue(habit.id, selected, 0);
                        return;
                      }
                      if (smartInput || habit.goal > 20) {
                        showLogSheet(context, habit: habit, day: selected);
                        return;
                      }
                      state.addHabitValue(habit.id, selected, 1);
                    },
                  ),
                ],
              ),
              if (state.habitDisplay != 'compact') ...[
                const SizedBox(height: 12),
                HabitSpanGrid(
                  habit: habit,
                  anchor: selected,
                  weekStart: weekStart,
                  display: state.habitDisplay,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Plus adds one unit. A large goal opens the logger. A finished habit clears.
class _Action extends StatelessWidget {
  const _Action({
    required this.done,
    required this.large,
    required this.color,
    required this.onTap,
  });

  final bool done;
  final bool large;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: done ? color : colors.muted.withValues(alpha: 0.7),
              width: 1.6,
            ),
          ),
          child: Icon(
            done
                ? Icons.check_rounded
                : large
                ? Icons.refresh_rounded
                : Icons.add_rounded,
            size: 20,
            color: colors.ink,
          ),
        ),
      ),
    );
  }
}

/// Plus adds one unit. A large goal opens the logger. A finished habit clears.
