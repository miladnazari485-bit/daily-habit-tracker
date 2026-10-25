import 'package:flutter/material.dart';

import '../data/habit_catalog.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/sheets.dart';

/// Suggested habits the user can add without typing a name.
///
/// Each section is one card. Count lists Fitness, Health, Mind, Chores,
/// and Reduce, and the chips wrap so the choices stay on the screen.
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
              key: const ValueKey('habit-picker-list'),
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
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search Habits',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            showComposer(context, kind: ComposerKind.habit),
                        child: const Text('Custom Habit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.ink,
                          side: BorderSide(color: colors.line),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _addTodo,
                        icon: const Icon(Icons.checklist_rounded, size: 18),
                        label: const Text('To-Do'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// True when the group has a suggestion matching the search text.
  bool _visible(HabitGroup group, String query) {
    if (query.isEmpty) return true;
    return group.all.any((item) => item.name.toLowerCase().contains(query));
  }

  /// Opens the task form. A saved to-do closes this screen so it shows on Today.
  Future<void> _addTodo() async {
    final before = AppScope.of(context).tasks.length;
    await showComposer(context, kind: ComposerKind.task);
    if (!mounted) return;
    if (AppScope.of(context).tasks.length > before) widget.onClose();
  }

  /// Adds the suggestion, or restores it when that name was archived.
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('${suggestion.name} was added.')),
    );
    widget.onClose();
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
    final topics = group.topics.isEmpty
        ? [HabitTopic(title: '', suggestions: group.suggestions)]
        : group.topics;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.chip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_icon(group.icon), size: 18, color: colors.ink),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.title,
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                group.detail,
                style: TextStyle(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              for (final topic in topics)
                _TopicRow(topic: topic, query: query, onPick: onPick),
            ],
          ),
        ),
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

/// A topic label and the habit chips that belong under it.
class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.query,
    required this.onPick,
  });

  final HabitTopic topic;
  final String query;
  final ValueChanged<HabitSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = topic.suggestions.where((item) {
      return query.isEmpty || item.name.toLowerCase().contains(query);
    }).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final labeled = topic.title.isNotEmpty;
    return Padding(
      key: ValueKey('topic-${topic.title}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labeled) ...[
            Text(
              '${topic.title}:',
              style: TextStyle(
                color: colors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                _SuggestionChip(suggestion: item, onPick: onPick),
            ],
          ),
        ],
      ),
    );
  }
}

/// One pastel habit name. Tapping it adds that habit.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.suggestion, required this.onPick});

  final HabitSuggestion suggestion;
  final ValueChanged<HabitSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    final color = Color(suggestion.colorValue);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onPick(suggestion),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            suggestion.name,
            style: TextStyle(
              color: foregroundOn(color),
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
