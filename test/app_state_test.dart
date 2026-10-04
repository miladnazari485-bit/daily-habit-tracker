import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/logic/dates.dart';
import 'package:habit_tracker/logic/habit_math.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/task_item.dart';
import 'package:habit_tracker/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'logs are separate per habit and per day, and future days are blocked',
    () async {
      final today = DateTime(2026, 10, 4);
      final state = AppState.withData(
        selected: today,
        habits: [
          Habit(
            id: 'wake',
            name: 'Wake Up Early',
            colorValue: 0xFFF6D452,
            kind: HabitKind.check,
            goal: 1,
            unit: 'time',
            createdAt: today,
          ),
          Habit(
            id: 'water',
            name: 'Drink Water',
            colorValue: 0xFFCBC6F6,
            kind: HabitKind.count,
            goal: 6,
            unit: 'liters',
            createdAt: today,
          ),
        ],
        tasks: [
          TaskItem(
            id: 'groceries',
            title: 'Buy groceries',
            dueDate: DateTime(2026, 9, 19),
          ),
        ],
      );

      expect(
        state.setHabitValue('wake', today.add(const Duration(days: 1)), 1),
        isFalse,
      );
      expect(state.toggleHabit('wake', today), isTrue);
      expect(isComplete(state.habitById('wake')!, today), isTrue);
      expect(isComplete(state.habitById('water')!, today), isFalse);

      state.addHabitValue('water', today, 2);
      state.addHabitValue('water', today.subtract(const Duration(days: 1)), 6);
      expect(valueOn(state.habitById('water')!, today), 2);
      expect(
        isComplete(
          state.habitById('water')!,
          today.subtract(const Duration(days: 1)),
        ),
        isTrue,
      );

      expect(state.overdueTasks(today), hasLength(1));
      state.postponeOverdueTo(today);
      expect(state.overdueTasks(today), isEmpty);
      expect(isSameDay(state.tasks.single.dueDate, today), isTrue);

      state.toggleTask('groceries');
      expect(state.tasks.single.done, isTrue);
    },
  );

  test('day and night mood and logs survive a reload', () async {
    final first = AppState();
    await first.load();
    expect(first.habits, hasLength(3));
    expect(first.night, isFalse);
    first.setNight(true);
    final today = dateOnly(DateTime.now());
    first.setHabitValue('wake', today, 1);
    await first.settled;

    final second = AppState();
    await second.load();
    expect(second.night, isTrue);
    expect(isComplete(second.habitById('wake')!, today), isTrue);
    expect(second.habitById('training')!.log[dateKey(today)], 1698);
  });
}
