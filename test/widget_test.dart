import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/task_item.dart';
import 'package:habit_tracker/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opening the app pins today and lists each habit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(HabitTrackerApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Wake Up Early'), findsWidgets);
    expect(find.text('Drink Water'), findsWidgets);
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('To-Do List'), findsOneWidget);
    expect(find.text('Daily Habits'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('To-Do List')).dy,
      lessThan(tester.getTopLeft(find.text('Daily Habits')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Buy groceries')).dy,
      lessThan(tester.getTopLeft(find.text('Wake Up Early')).dy),
    );

    await tester.drag(find.byKey(const ValueKey('today-list')), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('1,698 / 10,000 steps'), findsOneWidget);
  });

  testWidgets('reopens on the calendar month the user left', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final first = AppState();
    await first.load();
    first.rememberTab(2);
    first.rememberCalendarMonth(DateTime(2026, 2, 1));
    await first.settled;

    final restored = AppState();
    await restored.load();
    await tester.pumpWidget(HabitTrackerApp(state: restored));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('February 2026'), findsOneWidget);
  });

  testWidgets('journal, calendar, settings, and the habit picker open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(HabitTrackerApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Journal'));
    await tester.pumpAndSettle();
    expect(find.text('Journal'), findsWidgets);
    expect(find.text('All Labels'), findsOneWidget);

    await tester.tap(find.byTooltip('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      if (find.text('Sign in with Google').evaluate().isNotEmpty) break;
      await tester.drag(
        find.byKey(const ValueKey('settings-list')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Manage Account'), findsOneWidget);

    await tester.tap(find.byTooltip('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    expect(find.text('New Habit'), findsOneWidget);
    expect(find.text('Exercise'), findsOneWidget);
    expect(find.text('Custom Habit'), findsOneWidget);
    expect(
      find.text('Track how often you complete a task or activity'),
      findsOneWidget,
    );
    expect(find.text('Fitness:'), findsOneWidget);
    expect(find.text('Health:'), findsOneWidget);
    expect(find.text('Mind:'), findsOneWidget);
    expect(find.text('Chores:'), findsOneWidget);
    expect(find.text('Reduce:'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Pilates'),
      250,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('topic-Fitness')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Pilates'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Compact'), findsOneWidget);
    expect(find.textContaining('seven days'), findsNothing);
    expect(
      find.textContaining('Today keeps one week across the top'),
      findsOneWidget,
    );

    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('habit-grid-year')), findsWidgets);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('habit-grid-month')), findsWidgets);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compact'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('habit-grid-week')), findsNothing);
    expect(find.byKey(const ValueKey('habit-grid-month')), findsNothing);
    expect(find.byKey(const ValueKey('habit-grid-year')), findsNothing);
  });

  testWidgets('a finished habit drops into Completed and the section folds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final state = AppState.withData(
      habits: [
        Habit(
          id: 'wake',
          name: 'Wake Up Early',
          colorValue: 0xFFF6D452,
          kind: HabitKind.check,
          goal: 1,
          unit: 'time',
          createdAt: DateTime(2026, 10, 19),
        ),
      ],
    );
    await tester.pumpWidget(HabitTrackerApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Wake Up Early'), findsOneWidget);
    expect(find.text('0 / 1 time'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Wake Up Early'), findsNothing);
    expect(find.text('1 / 1 time'), findsNothing);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Wake Up Early'), findsOneWidget);
    expect(find.text('1 / 1 time'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Wake Up Early'), findsNothing);
  });

  testWidgets('a to-do comment stays one line until the title is tapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final state = AppState.withData(
      tasks: [
        TaskItem(
          id: 'groceries',
          title: 'Buy groceries',
          dueDate: DateTime(2026, 10, 25),
        ),
      ],
    );
    await tester.pumpWidget(HabitTrackerApp(state: state));
    await tester.pumpAndSettle();

    final commentField = find.descendant(
      of: find.byKey(const ValueKey('todo-list')),
      matching: find.byType(TextField),
    );
    final commentMark = find.descendant(
      of: find.byKey(const ValueKey('todo-list')),
      matching: find.byIcon(Icons.chat_bubble_outline_rounded),
    );
    expect(commentField, findsNothing);
    expect(commentMark, findsNothing);

    await tester.tap(find.text('Buy groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Comment'), findsOneWidget);

    await tester.enterText(commentField, 'Get the oat milk');
    await tester.pump();
    expect(state.tasks.single.note, 'Get the oat milk');

    await tester.tap(find.text('Buy groceries'));
    await tester.pumpAndSettle();
    expect(commentField, findsNothing);
    expect(find.text('Get the oat milk'), findsNothing);
    expect(commentMark, findsOneWidget);

    await tester.tap(find.text('Buy groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Get the oat milk'), findsOneWidget);
  });
}
