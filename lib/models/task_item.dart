import '../logic/dates.dart';

/// A one-off task with a single due date. Habits cover the repeating case.
class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required DateTime dueDate,
    this.done = false,
    this.minutes = 9 * 60,
  }) : dueDate = dateOnly(dueDate);

  final String id;
  final String title;
  final DateTime dueDate;
  final bool done;

  /// Minutes from midnight, used to place the task on the calendar.
  final int minutes;

  bool isOverdueOn(DateTime today) {
    return !done && dueDate.isBefore(dateOnly(today));
  }

  TaskItem copyWith({
    String? id,
    String? title,
    DateTime? dueDate,
    bool? done,
    int? minutes,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      done: done ?? this.done,
      minutes: minutes ?? this.minutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDate': dateKey(dueDate),
      'done': done,
      'minutes': minutes,
    };
  }

  static TaskItem? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    final due = raw['dueDate'];
    if (id is! String || title is! String || title.trim().isEmpty) return null;
    if (due is! String) return null;
    final dueDate = tryParseDateKey(due);
    if (dueDate == null) return null;
    final minutesRaw = raw['minutes'];
    final minutes = minutesRaw is num ? minutesRaw.round() : 9 * 60;
    return TaskItem(
      id: id,
      title: title.trim(),
      dueDate: dueDate,
      done: raw['done'] == true,
      minutes: minutes.clamp(0, 1439),
    );
  }
}
