import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final String appearance;
  final ValueChanged<String> onAppearance;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Drawer(
      backgroundColor: colors.scaffold,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
              const SizedBox(height: 6),
              Text(
                'Today keeps one week across the top. The month grid is on Calendar.',
                style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 22),
              Text(
                'Appearance',
                style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.chip,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _mini(colors, 'Day', appearance == 'day', () => onAppearance('day')),
                    _mini(
                      colors,
                      'Night',
                      appearance == 'night',
                      () => onAppearance('night'),
                    ),
                    _mini(
                      colors,
                      'System',
                      appearance == 'system',
                      () => onAppearance('system'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Checks, the journal, and this menu stay on this phone.',
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
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
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

