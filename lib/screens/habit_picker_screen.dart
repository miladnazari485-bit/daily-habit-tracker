import 'package:flutter/material.dart';

import '../data/habit_catalog.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/sheets.dart';

class HabitPickerScreen extends StatefulWidget {
  const HabitPickerScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<HabitPickerScreen> createState() => _HabitPickerScreenState();
}

class _HabitPickerScreenState extends State<HabitPickerScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final query = _search.text.trim().toLowerCase();
    return Material(
      color: colors.scaffold,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              MediaQuery.paddingOf(context).top + 8,
              16,
              4,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close_rounded, color: colors.ink),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'New Habit',
                        style: TextStyle(
                          color: colors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Try a suggestion...',
                        style: TextStyle(
                          color: colors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              children: [
                for (final group in habitCatalog)
                  if (_visible(group, query))
                    _GroupBlock(
                      group: group,
                      query: query,
                      onPick: (suggestion) => _add(suggestion),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search Habits',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 156,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => showComposer(context, kind: ComposerKind.habit),
                    child: const Text(
                      'Custom Habit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _visible(HabitGroup group, String query) {
    if (query.isEmpty) return true;
    return group.suggestions.any(
      (item) => item.name.toLowerCase().contains(query),
    );
  }

  void _add(HabitSuggestion suggestion) {
    final state = AppScope.of(context);
    final existing = state.habits.where(
      (habit) => habit.name.toLowerCase() == suggestion.name.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      final habit = existing.first;
      if (habit.archived) {
        state.setArchived(habit.id, false);
        widget.onClose();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${habit.name} is already on Today.')),
      );
      return;
    }
    state.addHabit(
      Habit(
        id: state.createId(),
        name: suggestion.name,
        colorValue: suggestion.colorValue,
        kind: suggestion.kind,
        goal: suggestion.goal,
        unit: suggestion.unit,
        createdAt: DateTime.now(),
      ),
    );
    widget.onClose();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${suggestion.name} was added.')),
    );
  }
}

class _GroupBlock extends StatelessWidget {
  const _GroupBlock({
    required this.group,
    required this.query,
    required this.onPick,
  });

  final HabitGroup group;
  final String query;
  final ValueChanged<HabitSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = group.suggestions.where((item) {
      return query.isEmpty || item.name.toLowerCase().contains(query);
    });
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(group.icon), size: 18, color: colors.muted),
              const SizedBox(width: 8),
              Text(
                group.title,
                style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            group.detail,
            style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Material(
                  color: Color(item.colorValue),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onPick(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        item.name,
                        style: TextStyle(
                          color: foregroundOn(Color(item.colorValue)),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _icon(String name) {
    switch (name) {
      case 'quit':
        return Icons.block_rounded;
      case 'health':
        return Icons.favorite_border_rounded;
      case 'journal':
        return Icons.menu_book_outlined;
      case 'mood':
        return Icons.mood_outlined;
      case 'weight':
        return Icons.monitor_weight_outlined;
      default:
        return Icons.check_box_outlined;
    }
  }
}
