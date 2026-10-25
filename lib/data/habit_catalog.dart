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

/// One sideways row inside a section, such as Fitness under Count.
class HabitTopic {
  const HabitTopic({required this.title, required this.suggestions});

  final String title;
  final List<HabitSuggestion> suggestions;
}

class HabitGroup {
  const HabitGroup({
    required this.title,
    required this.detail,
    required this.icon,
    this.topics = const [],
    this.suggestions = const [],
  });

  final String title;
  final String detail;
  final String icon;

  /// Named rows that scroll sideways. Count uses these five topics.
  final List<HabitTopic> topics;

  /// Used when the section has one row and no topic labels.
  final List<HabitSuggestion> suggestions;

  /// Every chip in the section, whether it sits in a topic or on its own.
  List<HabitSuggestion> get all {
    if (topics.isEmpty) return suggestions;
    return [for (final topic in topics) ...topic.suggestions];
  }
}

const _palette = <int>[
  0xFFF3A0B5,
  0xFFB7A6F5,
  0xFFF7C6A3,
  0xFFF6E7A1,
  0xFFCBC6F6,
  0xFFB7E4C7,
  0xFF7EC8B8,
  0xFFE07A4C,
  0xFFB7D4F5,
  0xFF7ED0D0,
  0xFFE7C56B,
  0xFFC4A07A,
];

const _namedColors = <String, int>{
  'Exercise': 0xFFF3A0B5,
  'Run': 0xFFB7A6F5,
  'Cardio': 0xFFF7C6A3,
  'Lift Weights': 0xFFF6E7A1,
  'Drink Water': 0xFFCBC6F6,
  'Wake Up Early': 0xFFF6D452,
  'Sleep Early': 0xFFB7E4C7,
  'Cook': 0xFF7EC8B8,
  'Read': 0xFFC7B6F2,
  'Study': 0xFFE07A4C,
  'Learn': 0xFFB7E4C7,
  'Meditate': 0xFFF7C6A3,
  'Clean': 0xFFC7B6F2,
  'Wash Dishes': 0xFFF3A0B5,
  'Laundry': 0xFFB7D4F5,
  'Vacuum': 0xFFD7E7A1,
  'Less Smoking': 0xFF7ED0D0,
  'Less Drinking': 0xFFB7A6F5,
  'Less Sweets': 0xFFE7C56B,
  'Less Coffee': 0xFFC4A07A,
  'Quit Smoking': 0xFF9AA8B5,
  'Quit Drinking': 0xFFE07A9C,
  'Quit Social Media': 0xFF6B9AF2,
  'Quit Nail Biting': 0xFFE7C56B,
};

/// A once-a-day habit, unless the name is something you measure.
HabitSuggestion _item(String name, int index) {
  final color = _namedColors[name] ?? _palette[index % _palette.length];
  switch (name) {
    case 'Drink Water':
      return HabitSuggestion(name: name, colorValue: color, goal: 6, unit: 'liters');
    case 'Read':
      return HabitSuggestion(name: name, colorValue: color, goal: 10, unit: 'pages');
    case 'Cardio':
    case 'Study':
      return HabitSuggestion(
        name: name,
        colorValue: color,
        goal: 30,
        unit: 'minutes',
      );
    case 'Meditate':
      return HabitSuggestion(
        name: name,
        colorValue: color,
        goal: 10,
        unit: 'minutes',
      );
    default:
      return HabitSuggestion(
        name: name,
        colorValue: color,
        goal: 1,
        unit: 'time',
        kind: HabitKind.check,
      );
  }
}

HabitTopic _topic(String title, List<String> names, {int offset = 0}) {
  return HabitTopic(
    title: title,
    suggestions: [
      for (var i = 0; i < names.length; i++) _item(names[i], i + offset),
    ],
  );
}

final habitCatalog = <HabitGroup>[
  HabitGroup(
    title: 'Count',
    detail: 'Track how often you complete a task or activity',
    icon: 'count',
    topics: [
      _topic('Fitness', const [
        'Exercise',
        'Run',
        'Cardio',
        'Lift Weights',
        'Work Out',
        'Stretch',
        'Yoga',
        'Dance Class',
        'Play Sport',
        'Bike',
        'Swim',
        'Pilates',
      ]),
      _topic('Health', const [
        'Drink Water',
        'Wake Up Early',
        'Sleep Early',
        'Cook',
        'Brush Teeth',
        'Floss',
        'Eat Fruits',
        'Eat Veggies',
        'Eat Breakfast',
        'Shower',
        'Visit Dentist',
        'Visit Doctor',
        'Visit Eye Doctor',
      ], offset: 4),
      _topic('Mind', const [
        'Read',
        'Study',
        'Learn',
        'Meditate',
        'Practice Language',
        'Journal',
        'Practice Piano',
        'Practice Guitar',
        'Practice Instrument',
        'Self Reflection',
        'Pray',
        'Deep Breathing',
      ], offset: 2),
      _topic('Chores', const [
        'Clean',
        'Wash Dishes',
        'Laundry',
        'Vacuum',
        'Dust',
        'Make Bed',
        'Grocery Shop',
        'Pay Bills',
        'Water Plants',
        'Feed Pet',
        'Take Out Trash',
      ], offset: 1),
      _topic('Reduce', const [
        'Less Smoking',
        'Less Drinking',
        'Less Sweets',
        'Less Coffee',
        'Less Junk Food',
        'Less Fast Food',
        'Less Eating Out',
        'Less Food Ordering',
        'Less Soda',
        'Less TV',
        'Less Netflix',
        'Less Shopping',
        'Less Gambling',
      ], offset: 9),
    ],
  ),
  HabitGroup(
    title: 'Quit',
    detail: "Track how long it's been since stopping a bad habit",
    icon: 'quit',
    suggestions: [
      _item('Quit Smoking', 0),
      _item('Quit Drinking', 1),
      _item('Quit Social Media', 7),
      _item('Quit Nail Biting', 3),
    ],
  ),
  HabitGroup(
    title: 'Health Connect',
    detail: 'Track your health & fitness activity data',
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
      _item('Journal', 4),
      _item('Positive Affirmations', 5),
      _item('Personal Note', 8),
    ],
  ),
  HabitGroup(
    title: 'Mood',
    detail: 'Track your mood and emotions over time',
    icon: 'mood',
    suggestions: [_item('Mood', 4)],
  ),
  HabitGroup(
    title: 'Body Weight',
    detail: 'Track your body weight progress and trends',
    icon: 'weight',
    suggestions: [
      const HabitSuggestion(name: 'Body Weight', colorValue: 0xFFF3B08A, goal: 1, unit: 'kg'),
    ],
  ),
];

String suggestionRow(HabitSuggestion suggestion) {
  if (suggestion.kind == HabitKind.check || suggestion.goal == 1) {
    return suggestion.unit == 'time' ? '1 time' : '1 ${suggestion.unit}';
  }
  return '${suggestion.goal} ${suggestion.unit}';
}
