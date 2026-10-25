import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_version.dart';
import '../logic/habit_math.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/page_header.dart';
import '../widgets/sheets.dart';

/// Appearance, week start, archive, export, and the on-device account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onMenu,
    required this.onAchievements,
  });

  final VoidCallback onMenu;
  final VoidCallback onAchievements;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    return Column(
      children: [
        PageHeader(
          title: 'Settings',
          night: state.night,
          onMenu: onAchievements,
          onToggleTheme: state.toggleNight,
          leadingIcon: Icons.star_border_rounded,
          leadingTooltip: 'Achievements',
          trailing: HeaderIconButton(
            tooltip: 'Open the side menu',
            onPressed: onMenu,
            child: Icon(Icons.menu_rounded, color: colors.ink, size: 22),
          ),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('settings-list'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              if (state.signedIn) _AccountCard(email: state.accountEmail!),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                onTap: () => _info(
                  context,
                  'Search',
                  'Search looks through habit names, to-dos, and journal notes saved on this phone.',
                ),
                decoration: const InputDecoration(
                  hintText: 'Search account for tasks, habits, notes...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _WideButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Ask for Help',
                      onTap: () => _info(
                        context,
                        'Help',
                        'Log a habit from Today, read the history in Journal, and see the week as color blocks on Calendar. Everything stays on this phone.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WideButton(
                      icon: Icons.school_outlined,
                      label: 'Tutorial',
                      onTap: () => _info(
                        context,
                        'Tutorial',
                        'The + button opens New Habit. Count has five sideways rows: Fitness, Health, Mind, Chores, and Reduce. The side menu switches every habit between Compact, Weekly, Monthly, and Yearly. Today keeps one week across the top. Tap a to-do to write a comment. The row stays one line until you tap it.',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _GroupLabel('App Settings'),
              _Row(
                title: 'Appearance',
                value: _appearanceLabel(state.appearance),
                onTap: () => _choose(
                  context,
                  'Appearance',
                  const ['Day', 'Color', 'Night'],
                  (choice) {
                    state.setAppearance(
                      choice == 'Day'
                          ? 'day'
                          : choice == 'Night'
                          ? 'night'
                          : 'color',
                    );
                  },
                ),
              ),
              _Row(
                title: 'Widgets',
                value: 'Customize',
                onTap: () => _info(
                  context,
                  'Widgets',
                  'Home screen widgets are not in this build. Habits, to-dos, and the journal are still saved on the phone.',
                ),
              ),
              _Row(
                title: 'Health Connect',
                value: 'Customize',
                onTap: () => _info(
                  context,
                  'Health Connect',
                  'Steps, distance, and calories are typed in here. This build does not read Health Connect or a watch.',
                ),
              ),
              _Row(
                title: 'Calendar Sync',
                value: state.calendarSync ? 'On' : 'Off',
                onTap: () => state.setCalendarSync(!state.calendarSync),
              ),
              _Row(
                title: 'Font Style',
                value: 'System',
                onTap: () => _info(
                  context,
                  'Font Style',
                  'This build uses one typeface so the pages stay close to the reference.',
                ),
              ),
              _Row(
                title: 'Font Size',
                value: state.fontSize == 'large' ? 'Large' : 'Default',
                onTap: () => state.setFontSize(
                  state.fontSize == 'large' ? 'default' : 'large',
                ),
              ),
              _Row(
                title: 'Week Start',
                value: state.weekStart == 1 ? 'Monday' : 'Sunday',
                onTap: () => state.setWeekStart(state.weekStart == 1 ? 0 : 1),
              ),
              _Row(
                title: 'Lists / Filters',
                value: 'Customize',
                onTap: () => _info(
                  context,
                  'Lists / Filters',
                  'Journal can filter by habit and by today, this week, or this month. Today splits open habits from completed ones.',
                ),
              ),
              _Row(
                title: 'Smart Input',
                value: state.smartInput ? 'On' : 'Off',
                onTap: () => state.setSmartInput(!state.smartInput),
              ),
              _Row(
                title: 'Timer Default',
                value: state.timerDefault == 'countdown' ? 'Countdown' : 'Stopwatch',
                onTap: () => state.setTimerDefault(
                  state.timerDefault == 'countdown' ? 'stopwatch' : 'countdown',
                ),
              ),
              _Row(
                title: 'Calendar Default',
                value: 'Week',
                onTap: () => _info(
                  context,
                  'Calendar',
                  'Today always shows the seven days of the current week. Open the Calendar tab for the month and the colored time grid.',
                ),
              ),
              _Row(
                title: 'Language',
                value: state.language == 'english' ? 'English' : 'Default',
                onTap: () => state.setLanguage(
                  state.language == 'english' ? 'default' : 'english',
                ),
              ),
              const SizedBox(height: 8),
              _Row(
                title: 'Support Habit Tracker',
                value: '',
                onTap: () => _info(
                  context,
                  'Support',
                  'There is no subscription. The tracker runs from the copy installed on your phone.',
                ),
              ),
              const SizedBox(height: 8),
              _BannerButton(
                color: const Color(0xFFB7A6F5),
                icon: Icons.thumb_up_alt_outlined,
                label: 'Rate on Play Store',
                onTap: () => _info(
                  context,
                  'Rate',
                  'This copy is installed from a file, so it is not listed on a store page.',
                ),
              ),
              _BannerButton(
                color: const Color(0xFFC7B6F2),
                icon: Icons.smartphone_rounded,
                label: 'Share link to App',
                onTap: () async {
                  await Clipboard.setData(
                    const ClipboardData(
                      text: 'Habit Tracker keeps checks, journal notes, and the calendar on this phone.',
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied a short description.')),
                  );
                },
              ),
              _BannerButton(
                color: const Color(0xFFF0A36B),
                icon: Icons.forum_outlined,
                label: 'Join the Community',
                onTap: () => _info(
                  context,
                  'Community',
                  'There is no online community for this build. Notes stay in your journal.',
                ),
              ),
              _BannerButton(
                color: const Color(0xFFF3A0B5),
                icon: Icons.camera_alt_outlined,
                label: 'Follow our Page',
                onTap: () => _info(
                  context,
                  'Page',
                  'This build does not open Instagram or any other site.',
                ),
              ),
              const SizedBox(height: 8),
              const _GroupLabel('Manage Account'),
              if (!state.signedIn)
                _BannerButton(
                  color: colors.card,
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Sign in with Google',
                  onTap: () => _signIn(context),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AccountCard(email: state.accountEmail!),
                ),
              _Row(
                title: 'Achievements',
                value: 'View',
                onTap: onAchievements,
              ),
              _Row(
                title: 'Habit Archive',
                value: 'View (${state.archivedHabits.length})',
                onTap: () => _archive(context),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _WideButton(
                      icon: Icons.logout_rounded,
                      label: 'Sign-Out',
                      onTap: () async {
                        if (!state.signedIn) {
                          _info(context, 'Sign out', 'No Google address is saved on this phone.');
                          return;
                        }
                        final ok = await confirmDelete(
                          context,
                          title: 'Sign out?',
                          message: 'The saved address is removed. Habits stay on this phone.',
                        );
                        if (ok) state.signOut();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WideButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete Account',
                      danger: true,
                      onTap: () async {
                        final ok = await confirmDelete(
                          context,
                          title: 'Delete account?',
                          message:
                              'This removes the saved address, habits, to-dos, and journal from this phone.',
                        );
                        if (ok) state.deleteAccount();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _WideButton(
                      icon: Icons.ios_share_rounded,
                      label: 'Export Data',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: state.exportJson()));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied a backup of the data on this phone.'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WideButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete Data',
                      danger: true,
                      onTap: () async {
                        final ok = await confirmDelete(
                          context,
                          title: 'Delete data?',
                          message: 'Habits, to-dos, and journal notes on this phone are cleared.',
                        );
                        if (ok) state.deleteBoard();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _QuietButton(
                      label: 'Terms of Service',
                      onTap: () => _info(
                        context,
                        'Terms',
                        'This tracker is for your own phone. It does not send habits or the journal anywhere.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuietButton(
                      label: 'Privacy Policy',
                      onTap: () => _info(
                        context,
                        'Privacy',
                        'Checks, notes, and the optional Google address are stored only in local app data.',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _QuietButton(label: 'Habit Tracker Version $appVersionName'),
              const SizedBox(height: 12),
              Material(
                color: const Color(0xFFC7B6F2),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _info(
                    context,
                    'Premium',
                    'Habit Tracker stays free on this phone. There is no subscription to buy.',
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Habit Tracker Premium',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'View what stays on this phone',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _appearanceLabel(String value) {
  switch (value) {
    case 'day':
      return 'Day';
    case 'night':
      return 'Night';
    case 'color':
      return 'Color';
    default:
      return 'System';
  }
}

Future<void> _info(BuildContext context, String title, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<void> _choose(
  BuildContext context,
  String title,
  List<String> items,
  ValueChanged<String> onChoice,
) async {
  final colors = AppColors.of(context);
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              ListTile(title: Text(item), onTap: () => Navigator.pop(context, item)),
          ],
        ),
      );
    },
  );
  if (choice != null) onChoice(choice);
}

Future<void> _signIn(BuildContext context) async {
  final colors = AppColors.of(context);
  final controller = TextEditingController(text: 'miladnazari485@gmail.com');
  final email = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in with Google',
              style: TextStyle(
                color: colors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The address is saved on this phone. This build does not contact Google.',
              style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    },
  );
  controller.dispose();
  if (!context.mounted || email == null) return;
  if (!email.contains('@')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter an email address.')),
    );
    return;
  }
  AppScope.of(context).signIn(email);
}

Future<void> _archive(BuildContext context) async {
  final state = AppScope.of(context);
  final colors = AppColors.of(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final archived = state.archivedHabits;
      return SafeArea(
        child: archived.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No archived habits. Open a habit and choose Archive.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final habit in archived)
                    ListTile(
                      title: Text(habit.name),
                      trailing: TextButton(
                        onPressed: () => state.setArchived(habit.id, false),
                        child: const Text('Restore'),
                      ),
                    ),
                ],
              ),
      );
    },
  );
}

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final today = DateTime.now();
    final anyLog = state.habits.any((habit) => habit.log.isNotEmpty);
    final week = state.habits.any((habit) => currentStreak(habit, today) >= 7);
    final notes = state.journal.length >= 3;
    final items = [
      ('First check', anyLog, 'Log any habit once.'),
      ('Seven-day streak', week, 'Finish one habit seven days in a row.'),
      ('Journal keeper', notes, 'Keep at least three journal lines.'),
    ];
    return Material(
      color: colors.scaffold,
      child: Column(
        children: [
          PageHeader(
            title: 'Achievements',
            night: state.night,
            onMenu: onClose,
            onToggleTheme: state.toggleNight,
            leadingIcon: Icons.close_rounded,
            leadingTooltip: 'Close',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.$2 ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                          color: item.$2 ? const Color(0xFFE7C56B) : colors.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$1,
                                style: TextStyle(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                item.$3,
                                style: TextStyle(
                                  color: colors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.of(context).ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.value, required this.onTap});

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              value,
              style: TextStyle(color: colors.muted, fontWeight: FontWeight.w700),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bg = danger ? const Color(0xFFE07A7A) : colors.chip;
    final ink = danger ? const Color(0xFF2A1214) : colors.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: ink),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = foregroundOn(color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.chip,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          const _GoogleMark(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Signed-in as $email',
              style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}
