import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/sheets.dart';
import 'calendar_screen.dart';
import 'habit_detail_screen.dart';
import 'habit_picker_screen.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'today_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;
  String? _detailId;
  bool _statsOpen = false;
  bool _achievementsOpen = false;
  bool _picking = false;
  bool _sessionApplied = false;

  /// Switches the bottom bar and closes any page that was covering the tabs.
  void _setTab(int index) {
    setState(() {
      _tab = index;
      _detailId = null;
      _statsOpen = false;
      _achievementsOpen = false;
      _picking = false;
    });
    final state = AppScope.of(context);
    state.rememberTab(index);
    state.rememberDetail(null);
  }

  /// Opens one habit's detail page and remembers it for the next launch.
  void _openHabit(String id) {
    setState(() {
      _detailId = id;
      _statsOpen = false;
      _picking = false;
    });
    AppScope.of(context).rememberDetail(id);
  }

  /// Leaves the habit page and returns to the tab underneath.
  void _closeHabit() {
    setState(() => _detailId = null);
    AppScope.of(context).rememberDetail(null);
  }

  /// Opens the side menu.
  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionApplied) {
      _sessionApplied = true;
      final saved = AppScope.of(context);
      _tab = saved.tab;
      final detail = saved.detailHabitId;
      if (detail != null && saved.habitById(detail) != null) {
        _detailId = detail;
      }
    }
    final colors = AppColors.of(context);
    final night = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: night ? Brightness.light : Brightness.dark,
        statusBarBrightness: night ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.scaffold,
        systemNavigationBarIconBrightness: night
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final drawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    final overlay = _detailId != null || _statsOpen || _achievementsOpen;
    return PopScope(
      canPop: !overlay && !_picking && !drawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.pop(context);
          return;
        }
        if (_picking) {
          setState(() => _picking = false);
          return;
        }
        if (_achievementsOpen) {
          setState(() => _achievementsOpen = false);
          return;
        }
        if (_statsOpen) {
          setState(() => _statsOpen = false);
          return;
        }
        if (_detailId != null) _closeHabit();
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        drawer: _AppDrawer(
          appearance: state.appearance,
          onAppearance: state.setAppearance,
          habitDisplay: state.habitDisplay,
          todayList: state.todayList,
          query: state.boardQuery,
          todayCount: _todayCount(state),
          taskCount: state.tasks.where((task) => !task.done).length,
          habitCount: state.activeHabits.length,
          onDisplay: state.setHabitDisplay,
          onList: state.setTodayList,
          onSearch: state.setBoardQuery,
        ),
        floatingActionButton: overlay || _picking || _tab == 3
            ? null
            : FloatingActionButton(
                tooltip: 'Add',
                backgroundColor: colors.fab,
                foregroundColor: colors.onFab,
                elevation: 2,
                shape: const CircleBorder(),
                onPressed: () {
                  if (_tab == 0 || _tab == 1) {
                    setState(() => _picking = true);
                  } else {
                    showComposer(context, kind: ComposerKind.task);
                  }
                },
                child: const Icon(Icons.add_rounded, size: 30),
              ),
        bottomNavigationBar: _BottomBar(index: _tab, onChanged: _setTab),
        body: Stack(
          children: [
            IndexedStack(
              index: _tab,
              children: [
                TodayScreen(
                  onMenu: _openMenu,
                  onOpenStats: () => setState(() {
                    _statsOpen = true;
                    _detailId = null;
                  }),
                  onOpenHabit: _openHabit,
                ),
                JournalScreen(onMenu: _openMenu),
                CalendarScreen(
                  onMenu: _openMenu,
                  onOpenDay: (day) {
                    state.selectDate(day);
                    _setTab(0);
                  },
                ),
                SettingsScreen(
                  onMenu: _openMenu,
                  onAchievements: () => setState(() => _achievementsOpen = true),
                ),
              ],
            ),
            if (_picking)
              Positioned.fill(
                child: HabitPickerScreen(
                  onClose: () => setState(() => _picking = false),
                ),
              ),
            if (_detailId != null)
              Positioned.fill(
                child: Material(
                  color: colors.scaffold,
                  child: HabitDetailScreen(
                    habitId: _detailId!,
                    onBack: _closeHabit,
                  ),
                ),
              ),
            if (_statsOpen)
              Positioned.fill(
                child: Material(
                  color: colors.scaffold,
                  child: StatsScreen(
                    onMenu: () => setState(() => _statsOpen = false),
                    onOpenHabit: _openHabit,
                  ),
                ),
              ),
            if (_achievementsOpen)
              Positioned.fill(
                child: AchievementsPage(
                  onClose: () => setState(() => _achievementsOpen = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const items = [
      (Icons.check_rounded, 'Today'),
      (Icons.article_outlined, 'Journal'),
      (Icons.calendar_today_rounded, 'Calendar'),
      (Icons.tune_rounded, 'Settings'),
    ];
    return Material(
      color: colors.scaffold,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  icon: items[i].$1,
                  label: items[i].$2,
                  selected: index == i,
                  onTap: () => onChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 64,
          height: 48,
          child: Icon(
            icon,
            size: selected ? 28 : 26,
            color: selected ? colors.ink : colors.muted.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.appearance,
    required this.onAppearance,
    required this.habitDisplay,
    required this.todayList,
    required this.query,
    required this.todayCount,
    required this.taskCount,
    required this.habitCount,
    required this.onDisplay,
    required this.onList,
    required this.onSearch,
  });

  final String appearance;
  final ValueChanged<String> onAppearance;
  final String habitDisplay;
  final String todayList;
  final String query;
  final int todayCount;
  final int taskCount;
  final int habitCount;
  final ValueChanged<String> onDisplay;
  final ValueChanged<String> onList;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Drawer(
      backgroundColor: colors.scaffold,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Habit Tracker',
              style: TextStyle(
                color: colors.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 14),
            const _SectionLabel('Lists / Filters'),
            _ChoiceRow(
              icon: Icons.calendar_today_rounded,
              label: 'Today View',
              count: todayCount,
              selected: todayList == 'today',
              onTap: () => onList('today'),
            ),
            _ChoiceRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'All Tasks',
              count: taskCount,
              selected: todayList == 'tasks',
              onTap: () => onList('tasks'),
            ),
            _ChoiceRow(
              icon: Icons.south_rounded,
              label: 'All Habits',
              count: habitCount,
              selected: todayList == 'habits',
              onTap: () => onList('habits'),
            ),
            const SizedBox(height: 8),
            const _SectionLabel('Habit Display'),
            _ChoiceRow(
              icon: Icons.menu_rounded,
              label: 'Compact',
              selected: habitDisplay == 'compact',
              onTap: () => onDisplay('compact'),
            ),
            _ChoiceRow(
              icon: Icons.view_week_outlined,
              label: 'Weekly',
              selected: habitDisplay == 'week',
              onTap: () => onDisplay('week'),
            ),
            _ChoiceRow(
              icon: Icons.calendar_view_month_rounded,
              label: 'Monthly',
              selected: habitDisplay == 'month',
              onTap: () => onDisplay('month'),
            ),
            _ChoiceRow(
              icon: Icons.apps_rounded,
              label: 'Yearly',
              selected: habitDisplay == 'year',
              onTap: () => onDisplay('year'),
            ),
            const SizedBox(height: 16),
            Text(
              'Appearance',
              style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.chip,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _mini(colors, 'Day', appearance == 'day', () => onAppearance('day')),
                  _mini(
                    colors,
                    'Color',
                    appearance == 'color',
                    () => onAppearance('color'),
                  ),
                  _mini(
                    colors,
                    'Night',
                    appearance == 'night',
                    () => onAppearance('night'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MenuSearch(query: query, onChanged: onSearch),
            const SizedBox(height: 16),
            Text(
              'Today keeps one week across the top. The month grid is on Calendar.',
              style: TextStyle(
                color: colors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(AppColors colors, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: selected ? colors.card : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

/// Counts open to-dos for the selected day plus habits that are still open.
int _todayCount(AppState state) {
  final today = dateOnly(DateTime.now());
  final selected = state.selectedDate;
  final tasks = state.tasks.where((task) {
    if (task.done) return false;
    if (isSameDay(task.dueDate, selected)) return true;
    return isSameDay(selected, today) && task.isOverdueOn(today);
  }).length;
  final habits = state.activeHabits.where((habit) {
    return !isComplete(habit, selected);
  }).length;
  return tasks + habits;
}

class _MenuSearch extends StatefulWidget {
  const _MenuSearch({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_MenuSearch> createState() => _MenuSearchState();
}

class _MenuSearchState extends State<_MenuSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(_MenuSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) _controller.text = widget.query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        hintText: 'Search Tasks & Habits...',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.line)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.chip,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: colors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.line)),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? colors.chip : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            onTap();
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B6CF6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      color: colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

