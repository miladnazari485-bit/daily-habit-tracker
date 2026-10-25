import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/sheets.dart';

/// First step after +. The user picks a habit or a to-do before anything is saved.
class AddChoiceScreen extends StatelessWidget {
  const AddChoiceScreen({
    super.key,
    required this.onClose,
    required this.onHabit,
    required this.onTodo,
  });

  final VoidCallback onClose;
  final VoidCallback onHabit;
  final VoidCallback onTodo;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.scaffold,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: colors.ink),
                ),
              ),
              Text(
                'Add',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose what this button should record.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 28),
              _ChoiceButton(
                icon: Icons.restart_alt_rounded,
                title: 'Habit',
                detail: 'A daily check. Each suggestion is saved as its own habit.',
                onTap: onHabit,
                buttonKey: const ValueKey('choose-habit'),
              ),
              const SizedBox(height: 12),
              _ChoiceButton(
                icon: Icons.checklist_rounded,
                title: 'To-Do List',
                detail: 'A one-time task. Each suggestion is saved on the to-do list.',
                onTap: onTodo,
                buttonKey: const ValueKey('choose-todo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    required this.buttonKey,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      key: buttonKey,
      color: colors.card,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: colors.weekday),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: TextStyle(
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Suggested to-dos. Tapping a name records that task and nothing else.
class TodoPickerScreen extends StatelessWidget {
  const TodoPickerScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  static const suggestions = <String>[
    'Buy groceries',
    'Pay bills',
    'Clean the house',
    'Call the doctor',
    'Reply to messages',
    'Take out trash',
    'Water plants',
    'Pack a bag',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.scaffold,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded, color: colors.ink),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'To-Do List',
                          style: TextStyle(
                            color: colors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Each button records its own task.',
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  for (final title in suggestions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TodoButton(
                        title: title,
                        onTap: () => _record(context, title),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: () => _custom(context),
                  child: const Text('Custom To-Do'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Saves [title] on the to-do list for the selected day.
  void _record(BuildContext context, String title) {
    final state = AppScope.of(context);
    final existing = state.tasks.where(
      (task) => !task.done && task.title.toLowerCase() == title.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title is already on the to-do list.')),
      );
      return;
    }
    final today = dateOnly(DateTime.now());
    final selected = state.selectedDate;
    final due = selected.isBefore(today) ? today : selected;
    state.addTask(
      TaskItem(
        id: state.createId(),
        title: title,
        dueDate: due,
        minutes: 9 * 60,
      ),
    );
    onClose();
  }

  /// Opens the task form. A saved task closes this screen.
  Future<void> _custom(BuildContext context) async {
    final before = AppScope.of(context).tasks.length;
    await showComposer(context, kind: ComposerKind.task);
    if (!context.mounted) return;
    if (AppScope.of(context).tasks.length > before) onClose();
  }
}

class _TodoButton extends StatelessWidget {
  const _TodoButton({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(side: BorderSide(color: colors.line)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.check_box_outline_blank_rounded, color: colors.weekday),
              const SizedBox(width: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
