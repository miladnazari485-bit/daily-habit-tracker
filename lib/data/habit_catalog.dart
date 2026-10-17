import '../models/habit.dart';

class HabitSuggestion {
  const HabitSuggestion({
    required this.name,
    required this.colorValue,
    required this.goal,
    required this.unit,
    this.kind = HabitKind.count,
  });

  final String name;
  final int colorValue;
  final int goal;
  final String unit;
  final HabitKind kind;
}

class HabitGroup {
  const HabitGroup({
    required this.title,
    required this.detail,
    required this.icon,
    required this.suggestions,
  });

  final String title;
  final String detail;
  final String icon;
  final List<HabitSuggestion> suggestions;
}

const habitCatalog = <HabitGroup>[
  HabitGroup(
    title: 'Count',
    detail: 'Track how often you complete a task or activity',
    icon: 'count',
    suggestions: [
      HabitSuggestion(name: 'Exercise', colorValue: 0xFFF3A0B5, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Run', colorValue: 0xFFB7A6F5, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Cardio', colorValue: 0xFFF7C6A3, goal: 30, unit: 'minutes'),
      HabitSuggestion(name: 'Lift Weights', colorValue: 0xFFF6E7A1, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Drink Water', colorValue: 0xFFD7D4F8, goal: 6, unit: 'liters'),
      HabitSuggestion(name: 'Wake Up Early', colorValue: 0xFFF6D452, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Sleep Early', colorValue: 0xFFB7E4C7, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Cook', colorValue: 0xFF8FCB8A, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Read', colorValue: 0xFFD7D4F8, goal: 10, unit: 'pages'),
      HabitSuggestion(name: 'Study', colorValue: 0xFFE07A4C, goal: 30, unit: 'minutes'),
      HabitSuggestion(name: 'Learn', colorValue: 0xFFB7E4C7, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Meditate', colorValue: 0xFFF7C6A3, goal: 10, unit: 'minutes'),
      HabitSuggestion(name: 'Clean', colorValue: 0xFFC7B6F2, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Wash Dishes', colorValue: 0xFFF3A0B5, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Laundry', colorValue: 0xFFB7D4F5, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Vacuum', colorValue: 0xFFD7E7A1, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Less Smoking', colorValue: 0xFF7ED0D0, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Less Drinking', colorValue: 0xFFB7A6F5, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Less Sweets', colorValue: 0xFFE7C56B, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Less Coffee', colorValue: 0xFFC7B6F2, goal: 1, unit: 'time', kind: HabitKind.check),
    ],
  ),
  HabitGroup(
    title: 'Quit',
    detail: "Track how long it's been since stopping a bad habit",
    icon: 'quit',
    suggestions: [
      HabitSuggestion(name: 'Quit Smoking', colorValue: 0xFF9AA3B2, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Quit Drinking', colorValue: 0xFFE07A9C, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Quit Social Media', colorValue: 0xFF7EA2F2, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Quit Nail Biting', colorValue: 0xFFE7C56B, goal: 1, unit: 'time', kind: HabitKind.check),
    ],
  ),
  HabitGroup(
    title: 'Health Connect',
    detail: 'Track your health and fitness activity',
    icon: 'health',
    suggestions: [
      HabitSuggestion(name: 'Steps', colorValue: 0xFFB7A6F5, goal: 10000, unit: 'steps'),
      HabitSuggestion(name: 'Walk', colorValue: 0xFFF3A0B5, goal: 30, unit: 'minutes'),
      HabitSuggestion(name: 'Move Distance', colorValue: 0xFF7ED0C8, goal: 5, unit: 'km'),
      HabitSuggestion(name: 'Calorie Intake', colorValue: 0xFFB7E4C7, goal: 2000, unit: 'kcal'),
    ],
  ),
  HabitGroup(
    title: 'Journal',
    detail: 'Track how much you write in your journal',
    icon: 'journal',
    suggestions: [
      HabitSuggestion(name: 'Journal', colorValue: 0xFFC7B6F2, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Self Reflection', colorValue: 0xFFF6D452, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Positive Affirmations', colorValue: 0xFFD7D4F8, goal: 1, unit: 'time', kind: HabitKind.check),
      HabitSuggestion(name: 'Personal Note', colorValue: 0xFF9EC0F6, goal: 1, unit: 'time', kind: HabitKind.check),
    ],
  ),
  HabitGroup(
    title: 'Mood',
    detail: 'Track your mood and emotions over time',
    icon: 'mood',
    suggestions: [
      HabitSuggestion(name: 'Mood', colorValue: 0xFFC7B6F2, goal: 1, unit: 'time', kind: HabitKind.check),
    ],
  ),
  HabitGroup(
    title: 'Body Weight',
    detail: 'Track your body weight progress and trends',
    icon: 'weight',
    suggestions: [
      HabitSuggestion(name: 'Body Weight', colorValue: 0xFFF3B08A, goal: 1, unit: 'kg'),
    ],
  ),
];

String suggestionRow(HabitSuggestion suggestion) {
  if (suggestion.kind == HabitKind.check || suggestion.goal == 1) {
    return suggestion.unit == 'time' ? '1 time' : '1 ${suggestion.unit}';
  }
  return '${suggestion.goal} ${suggestion.unit}';
}
