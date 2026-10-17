import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/habit_card.dart';
import '../widgets/page_header.dart';
import '../widgets/sheets.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _search = TextEditingController();
  String _label = 'All Labels';
  String _range = 'All Entries';
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final query = _search.text.trim().toLowerCase();
    final today = dateOnly(DateTime.now());
    final labels = <String>{
      'All Labels',
      for (final habit in state.habits) habit.name,
      for (final entry in state.journal)
        if (entry.habitId == null) entry.title,
    };
    final entries = state.journal.where((entry) {
      final habit = entry.habitId == null ? null : state.habitById(entry.habitId!);
      final name = habit?.name ?? entry.title;
      if (_label != 'All Labels' && name != _label) return false;
      if (query.isNotEmpty && !name.toLowerCase().contains(query)) return false;
      if (_range == 'Today' && !isSameDay(entry.at, today)) return false;
      if (_range == 'This Week') {
        final start = startOfWeek(today, weekStart: state.weekStart);
        final end = start.add(const Duration(days: 7));
        if (entry.at.isBefore(start) || !entry.at.isBefore(end)) return false;
      }
      if (_range == 'This Month' &&
          (entry.at.year != today.year || entry.at.month != today.month)) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Journal',
          night: state.night,
          onMenu: widget.onMenu,
          onToggleTheme: state.toggleNight,
          leadingIcon: Icons.bookmark_border_rounded,
          leadingTooltip: 'Open the side menu',
          trailing: HeaderIconButton(
            tooltip: 'Journal options',
            onPressed: () => _more(context),
            child: Icon(Icons.more_horiz_rounded, color: colors.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              HeaderIconButton(
                tooltip: 'Search journal',
                onPressed: () => setState(() => _searching = !_searching),
                child: Icon(Icons.search_rounded, color: colors.ink),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterChip(
                  label: _label,
                  onTap: () async {
                    final choice = await _pick(context, 'Label', labels.toList());
                    if (choice != null) setState(() => _label = choice);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterChip(
                  label: _range,
                  onTap: () async {
                    final choice = await _pick(context, 'Entries', const [
                      'All Entries',
                      'Today',
                      'This Week',
                      'This Month',
                    ]);
                    if (choice != null) setState(() => _range = choice);
                  },
                ),
              ),
            ],
          ),
        ),
        if (_searching)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Search entries'),
            ),
          ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'No journal entries for this filter.',
                    style: TextStyle(
                      color: colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final habit = entry.habitId == null
                        ? null
                        : state.habitById(entry.habitId!);
                    final name = habit?.name ?? entry.title;
                    final color = Color(habit?.colorValue ?? entry.colorValue);
                    final amount = entry.unit == 'note'
                        ? 'note'
                        : '${formatInt(entry.amount)} ${entry.unit}';
                    return Material(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 92,
                              child: Text(
                                journalWhen(entry.at),
                                style: TextStyle(
                                  color: colors.muted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Flexible(
                              child: HabitNameChip(name: name, color: color),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              amount,
                              style: TextStyle(
                                color: colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Entry options',
                              onPressed: () => _entryMenu(context, entry),
                              icon: Icon(Icons.more_horiz_rounded, color: colors.muted),
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

  Future<void> _more(BuildContext context) async {
    final choice = await _pick(context, 'Journal', const [
      'Add a note',
      'Log a habit',
      'Clear filters',
    ]);
    if (!mounted || choice == null) return;
    if (choice == 'Clear filters') {
      setState(() {
        _label = 'All Labels';
        _range = 'All Entries';
        _search.clear();
      });
      return;
    }
    if (choice == 'Add a note') {
      await _addNote();
      return;
    }
    await _logHabit();
  }

  Future<void> _entryMenu(BuildContext context, JournalEntry entry) async {
    final choice = await _pick(context, 'Entry', const ['Delete entry']);
    if (!context.mounted || choice == null) return;
    AppScope.of(context).deleteJournal(entry.id);
  }

  Future<void> _addNote() async {
    final colors = AppColors.of(context);
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Journal note'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'What happened?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.ink),
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || text == null || text.trim().isEmpty) return;
    AppScope.of(context).addNote(text, DateTime.now());
  }

  Future<void> _logHabit() async {
    final state = AppScope.of(context);
    final habits = state.activeHabits;
    if (habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a habit on Today first.')),
      );
      return;
    }
    final names = habits.map((habit) => habit.name).toList();
    final choice = await _pick(context, 'Log a habit', names);
    if (!mounted || choice == null) return;
    final habit = habits.firstWhere((item) => item.name == choice);
    await showLogSheet(context, habit: habit, day: state.selectedDate);
  }

  Future<String?> _pick(BuildContext context, String title, List<String> items) {
    final colors = AppColors.of(context);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              for (final item in items)
                ListTile(
                  title: Text(item),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.chip,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded, color: colors.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
