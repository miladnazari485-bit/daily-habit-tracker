import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../logic/dates.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/task_item.dart';

const storageKey = 'habit_tracker.v1';

/// In-memory board plus the on-device JSON copy.
class AppState extends ChangeNotifier {
  AppState() : _habits = [], _tasks = [], _journal = [];

  AppState.withData({
    List<Habit>? habits,
    List<TaskItem>? tasks,
    List<JournalEntry>? journal,
    DateTime? selected,
    bool night = false,
    String? appearance,
    int tab = 0,
    DateTime? todayMonth,
    bool habitsOpen = true,
    DateTime? calendarMonth,
    String? detailHabitId,
    DateTime? detailMonth,
    String span = 'week',
  }) : _habits = List<Habit>.of(habits ?? const []),
       _tasks = List<TaskItem>.of(tasks ?? const []),
       _journal = List<JournalEntry>.of(journal ?? const []),
       _selectedDate = dateOnly(selected ?? DateTime.now()),
       _ready = true {
    _appearance = appearance ?? (night ? 'night' : 'day');
    _tab = tab < 0 || tab > 3 ? 0 : tab;
    _habitsOpen = habitsOpen;
    _span = span == 'month' ? 'month' : 'week';
    _detailHabitId = detailHabitId;
    final anchor = _selectedDate;
    _todayMonth = DateTime(
      (todayMonth ?? anchor).year,
      (todayMonth ?? anchor).month,
    );
    _calendarMonth = DateTime(
      (calendarMonth ?? anchor).year,
      (calendarMonth ?? anchor).month,
    );
    if (detailMonth != null) {
      _detailMonth = DateTime(detailMonth.year, detailMonth.month);
    }
  }

  final List<Habit> _habits;
  final List<TaskItem> _tasks;
  final List<JournalEntry> _journal;
  DateTime _selectedDate = dateOnly(DateTime.now());
  String _appearance = 'system';
  int _tab = 0;
  bool _habitsOpen = true;
  bool _todosOpen = true;
  bool _completedOpen = false;
  String _span = 'week';
  String _calendarDefault = 'auto';
  int _weekStart = 0;
  String _fontSize = 'default';
  String? _accountEmail;
  String _timerDefault = 'stopwatch';
  String _language = 'default';
  bool _calendarSync = true;
  bool _smartInput = false;
  DateTime _todayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _detailHabitId;
  DateTime? _detailMonth;
  bool _ready = false;
  bool _loading = false;
  Future<void> _queue = Future<void>.value();
  int _idSequence = 0;

  bool get ready => _ready;
  bool get night => _appearance == 'night';
  String get appearance => _appearance;
  ThemeMode get themeMode {
    switch (_appearance) {
      case 'day':
        return ThemeMode.light;
      case 'night':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  DateTime get selectedDate => _selectedDate;
  int get tab => _tab;
  bool get habitsOpen => _habitsOpen;
  bool get todosOpen => _todosOpen;
  bool get completedOpen => _completedOpen;
  String get span => _span;
  String get calendarDefault => _calendarDefault;
  String get todaySpan {
    if (_calendarDefault == 'week' || _calendarDefault == 'month') {
      return _calendarDefault;
    }
    return _span;
  }

  int get weekStart => _weekStart;
  String get fontSize => _fontSize;
  double get fontScale => _fontSize == 'large' ? 1.12 : 1;
  String? get accountEmail => _accountEmail;
  bool get signedIn => _accountEmail != null && _accountEmail!.isNotEmpty;
  String get timerDefault => _timerDefault;
  String get language => _language;
  bool get calendarSync => _calendarSync;
  bool get smartInput => _smartInput;
  DateTime get todayMonth => _todayMonth;
  DateTime get calendarMonth => _calendarMonth;
  String? get detailHabitId => _detailHabitId;
  DateTime? get detailMonth => _detailMonth;
  List<Habit> get habits => List<Habit>.unmodifiable(_habits);
  List<Habit> get activeHabits =>
      List<Habit>.unmodifiable(_habits.where((habit) => !habit.archived));
  List<Habit> get archivedHabits =>
      List<Habit>.unmodifiable(_habits.where((habit) => habit.archived));
  List<TaskItem> get tasks => List<TaskItem>.unmodifiable(_tasks);
  List<JournalEntry> get journal {
    final items = List<JournalEntry>.of(_journal);
    items.sort((a, b) => b.at.compareTo(a.at));
    return List<JournalEntry>.unmodifiable(items);
  }

  /// Completes after the latest scheduled write finishes.
  Future<void> get settled => _queue;

  List<TaskItem> overdueTasks([DateTime? today]) {
    final day = dateOnly(today ?? DateTime.now());
    final items = _tasks.where((task) => task.isOverdueOn(day)).toList();
    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }

  Habit? habitById(String id) {
    for (final habit in _habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  Future<void> load() async {
    if (_ready || _loading) return;
    _loading = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    final decoded = raw == null ? null : _decode(raw);
    if (decoded == null) {
      final seed = buildSeed(DateTime.now());
      _habits
        ..clear()
        ..addAll(seed.habits);
      _tasks
        ..clear()
        ..addAll(seed.tasks);
      _journal
        ..clear()
        ..addAll(seed.journal);
      _appearance = 'system';
    } else {
      _appearance = decoded.night ? 'night' : 'day';
      _habits
        ..clear()
        ..addAll(decoded.habits);
      _tasks
        ..clear()
        ..addAll(decoded.tasks);
      _journal
        ..clear()
        ..addAll(decoded.journal);
      _applySession(decoded.session);
      _applySettings(decoded.settings);
    }
    if (_detailHabitId != null && habitById(_detailHabitId!) == null) {
      _detailHabitId = null;
    }
    _ready = true;
    _loading = false;
    notifyListeners();
    if (decoded == null) _scheduleSave();
  }

  void selectDate(DateTime day) {
    final next = dateOnly(day);
    if (isSameDay(next, _selectedDate)) return;
    _selectedDate = next;
    notifyListeners();
    _scheduleSave();
  }

  void rememberTab(int index) {
    if (index < 0 || index > 3 || _tab == index) return;
    _tab = index;
    _scheduleSave();
  }

  void rememberHabitsOpen(bool value) {
    if (_habitsOpen == value) return;
    _habitsOpen = value;
    _scheduleSave();
  }

  void rememberTodayMonth(DateTime month) {
    final next = DateTime(month.year, month.month);
    if (isSameMonth(_todayMonth, next)) return;
    _todayMonth = next;
    _scheduleSave();
  }

  void rememberCalendarMonth(DateTime month) {
    final next = DateTime(month.year, month.month);
    if (isSameMonth(_calendarMonth, next)) return;
    _calendarMonth = next;
    _scheduleSave();
  }

  /// Remembers which habit page is open. Pass null when the user leaves it.
  void rememberDetail(String? id) {
    if (_detailHabitId == id) return;
    _detailHabitId = id;
    _scheduleSave();
  }

  void rememberDetailMonth(DateTime month) {
    final next = DateTime(month.year, month.month);
    if (_detailMonth != null && isSameMonth(_detailMonth!, next)) return;
    _detailMonth = next;
    _scheduleSave();
  }

  void setAppearance(String value) {
    const allowed = {'system', 'day', 'night'};
    if (!allowed.contains(value) || _appearance == value) return;
    _appearance = value;
    notifyListeners();
    _scheduleSave();
  }

  void setNight(bool value) => setAppearance(value ? 'night' : 'day');

  void toggleNight() => setNight(!night);

  void rememberTodosOpen(bool value) {
    if (_todosOpen == value) return;
    _todosOpen = value;
    _scheduleSave();
  }

  void rememberCompletedOpen(bool value) {
    if (_completedOpen == value) return;
    _completedOpen = value;
    _scheduleSave();
  }

  /// Weekly or monthly layout for the first page.
  void rememberSpan(String value) {
    if (value != 'week' && value != 'month') return;
    if (_span == value && _calendarDefault == 'auto') return;
    _span = value;
    _calendarDefault = 'auto';
    notifyListeners();
    _scheduleSave();
  }

  void setCalendarDefault(String value) {
    const allowed = {'auto', 'week', 'month'};
    if (!allowed.contains(value) || _calendarDefault == value) return;
    _calendarDefault = value;
    notifyListeners();
    _scheduleSave();
  }

  void setWeekStart(int value) {
    final next = value == 1 ? 1 : 0;
    if (_weekStart == next) return;
    _weekStart = next;
    notifyListeners();
    _scheduleSave();
  }

  void setFontSize(String value) {
    final next = value == 'large' ? 'large' : 'default';
    if (_fontSize == next) return;
    _fontSize = next;
    notifyListeners();
    _scheduleSave();
  }

  void setTimerDefault(String value) {
    final next = value == 'countdown' ? 'countdown' : 'stopwatch';
    if (_timerDefault == next) return;
    _timerDefault = next;
    notifyListeners();
    _scheduleSave();
  }

  void setLanguage(String value) {
    final next = value == 'english' ? 'english' : 'default';
    if (_language == next) return;
    _language = next;
    notifyListeners();
    _scheduleSave();
  }

  void setCalendarSync(bool value) {
    if (_calendarSync == value) return;
    _calendarSync = value;
    notifyListeners();
    _scheduleSave();
  }

  void setSmartInput(bool value) {
    if (_smartInput == value) return;
    _smartInput = value;
    notifyListeners();
    _scheduleSave();
  }

  void signIn(String email) {
    final next = email.trim();
    if (next.isEmpty || !next.contains('@')) return;
    if (_accountEmail == next) return;
    _accountEmail = next;
    notifyListeners();
    _scheduleSave();
  }

  void signOut() {
    if (_accountEmail == null) return;
    _accountEmail = null;
    notifyListeners();
    _scheduleSave();
  }

  void deleteBoard() {
    _habits.clear();
    _tasks.clear();
    _journal.clear();
    _detailHabitId = null;
    notifyListeners();
    _scheduleSave();
  }

  void deleteAccount() {
    _accountEmail = null;
    deleteBoard();
  }

  bool setHabitValue(String id, DateTime day, int value) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(day);
    if (target.isAfter(today)) return false;
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index < 0) return false;
    final habit = _habits[index];
    final log = Map<String, int>.from(habit.log);
    if (value <= 0) {
      log.remove(dateKey(target));
    } else {
      log[dateKey(target)] = value;
    }
    _habits[index] = habit.copyWith(log: log);
    _replaceJournal(
      habitId: habit.id,
      title: habit.name,
      colorValue: habit.colorValue,
      unit: habit.unit,
      day: target,
      amount: value,
    );
    notifyListeners();
    _scheduleSave();
    return true;
  }

  bool addHabitValue(String id, DateTime day, int delta) {
    final habit = habitById(id);
    if (habit == null) return false;
    final next = valueOnSafe(habit, day) + delta;
    return setHabitValue(id, day, next);
  }

  bool toggleHabit(String id, DateTime day) {
    final habit = habitById(id);
    if (habit == null) return false;
    final done = valueOnSafe(habit, day) >= habit.goal;
    return setHabitValue(id, day, done ? 0 : habit.goal);
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
    notifyListeners();
    _scheduleSave();
  }

  void updateHabit(Habit habit) {
    final index = _habits.indexWhere((item) => item.id == habit.id);
    if (index < 0) return;
    _habits[index] = habit.copyWith(log: _habits[index].log);
    notifyListeners();
    _scheduleSave();
  }

  void deleteHabit(String id) {
    _habits.removeWhere((habit) => habit.id == id);
    _journal.removeWhere((entry) => entry.habitId == id);
    if (_detailHabitId == id) _detailHabitId = null;
    notifyListeners();
    _scheduleSave();
  }

  void setArchived(String id, bool archived) {
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index < 0 || _habits[index].archived == archived) return;
    _habits[index] = _habits[index].copyWith(archived: archived);
    if (archived && _detailHabitId == id) _detailHabitId = null;
    notifyListeners();
    _scheduleSave();
  }

  void addNote(String title, DateTime at) {
    final text = title.trim();
    if (text.isEmpty) return;
    _journal.add(
      JournalEntry(
        id: createId(),
        title: text,
        amount: 1,
        unit: 'note',
        at: at,
        colorValue: 0xFFC7B6F2,
      ),
    );
    notifyListeners();
    _scheduleSave();
  }

  void deleteJournal(String id) {
    final before = _journal.length;
    _journal.removeWhere((entry) => entry.id == id);
    if (_journal.length == before) return;
    notifyListeners();
    _scheduleSave();
  }

  void addTask(TaskItem task) {
    _tasks.add(task);
    notifyListeners();
    _scheduleSave();
  }

  void updateTask(TaskItem task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    _tasks[index] = task;
    notifyListeners();
    _scheduleSave();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    final task = _tasks[index];
    _tasks[index] = task.copyWith(done: !task.done);
    notifyListeners();
    _scheduleSave();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
    _scheduleSave();
  }

  void postponeOverdueTo(DateTime day) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(day);
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (!task.isOverdueOn(today)) continue;
      _tasks[i] = task.copyWith(dueDate: target);
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _scheduleSave();
  }

  void postponeTask(String id, DateTime day) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    _tasks[index] = _tasks[index].copyWith(dueDate: dateOnly(day));
    notifyListeners();
    _scheduleSave();
  }

  String createId() {
    _idSequence += 1;
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$_idSequence';
  }

  void _scheduleSave() {
    if (!_ready) return;
    _queue = _queue.then((_) => _write());
  }

  Future<void> _write() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(_snapshot()));
  }

  String exportJson() => jsonEncode(_snapshot());

  Map<String, dynamic> _snapshot() {
    return {
      'night': night,
      'habits': _habits.map((habit) => habit.toJson()).toList(),
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'journal': _journal.map((entry) => entry.toJson()).toList(),
      'settings': {
        'appearance': _appearance,
        'span': _span,
        'calendarDefault': _calendarDefault,
        'weekStart': _weekStart,
        'fontSize': _fontSize,
        'accountEmail': _accountEmail,
        'timerDefault': _timerDefault,
        'language': _language,
        'calendarSync': _calendarSync,
        'smartInput': _smartInput,
      },
      'session': {
        'tab': _tab,
        'selectedDate': dateKey(_selectedDate),
        'todayMonth': monthKey(_todayMonth),
        'habitsOpen': _habitsOpen,
        'todosOpen': _todosOpen,
        'completedOpen': _completedOpen,
        'calendarMonth': monthKey(_calendarMonth),
        'detailHabitId': _detailHabitId,
        'detailMonth': _detailMonth == null ? null : monthKey(_detailMonth!),
      },
    };
  }

  void _replaceJournal({
    required String habitId,
    required String title,
    required int colorValue,
    required String unit,
    required DateTime day,
    required int amount,
  }) {
    _journal.removeWhere(
      (entry) => entry.habitId == habitId && isSameDay(entry.at, day),
    );
    if (amount <= 0) return;
    final now = DateTime.now();
    _journal.add(
      JournalEntry(
        id: createId(),
        habitId: habitId,
        title: title,
        amount: amount,
        unit: unit,
        at: DateTime(day.year, day.month, day.day, now.hour, now.minute),
        colorValue: colorValue,
      ),
    );
  }

  void _applySettings(Map<String, dynamic>? settings) {
    if (settings == null) return;
    final appearance = settings['appearance'];
    if (appearance == 'system' || appearance == 'day' || appearance == 'night') {
      _appearance = appearance as String;
    }
    final span = settings['span'];
    if (span == 'week' || span == 'month') _span = span as String;
    final calendarDefault = settings['calendarDefault'];
    if (calendarDefault == 'auto' ||
        calendarDefault == 'week' ||
        calendarDefault == 'month') {
      _calendarDefault = calendarDefault as String;
    }
    final weekStart = settings['weekStart'];
    if (weekStart is num) _weekStart = weekStart.round() == 1 ? 1 : 0;
    final fontSize = settings['fontSize'];
    if (fontSize == 'large' || fontSize == 'default') {
      _fontSize = fontSize as String;
    }
    final email = settings['accountEmail'];
    _accountEmail = email is String && email.contains('@') ? email : null;
    final timer = settings['timerDefault'];
    if (timer == 'stopwatch' || timer == 'countdown') {
      _timerDefault = timer as String;
    }
    final language = settings['language'];
    if (language == 'default' || language == 'english') {
      _language = language as String;
    }
    if (settings['calendarSync'] is bool) {
      _calendarSync = settings['calendarSync'] as bool;
    }
    if (settings['smartInput'] is bool) {
      _smartInput = settings['smartInput'] as bool;
    }
  }

  void _applySession(Map<String, dynamic>? session) {
    if (session == null) return;
    final tab = session['tab'];
    if (tab is int && tab >= 0 && tab <= 3) _tab = tab;
    final selected = session['selectedDate'];
    if (selected is String) {
      final parsed = tryParseDateKey(selected);
      if (parsed != null) _selectedDate = parsed;
    }
    final todayMonth = session['todayMonth'];
    if (todayMonth is String) {
      final parsed = tryParseMonthKey(todayMonth);
      if (parsed != null) _todayMonth = parsed;
    }
    final habitsOpen = session['habitsOpen'];
    if (habitsOpen is bool) _habitsOpen = habitsOpen;
    final todosOpen = session['todosOpen'];
    if (todosOpen is bool) _todosOpen = todosOpen;
    final completedOpen = session['completedOpen'];
    if (completedOpen is bool) _completedOpen = completedOpen;
    final calendarMonth = session['calendarMonth'];
    if (calendarMonth is String) {
      final parsed = tryParseMonthKey(calendarMonth);
      if (parsed != null) _calendarMonth = parsed;
    }
    final detail = session['detailHabitId'];
    _detailHabitId = detail is String && detail.isNotEmpty ? detail : null;
    final detailMonth = session['detailMonth'];
    if (detailMonth is String) {
      _detailMonth = tryParseMonthKey(detailMonth);
    }
  }

  static _Decoded? _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final habits = <Habit>[];
      final habitRaw = value['habits'];
      if (habitRaw is List) {
        for (final item in habitRaw) {
          final habit = Habit.tryParse(item);
          if (habit != null) habits.add(habit);
        }
      }
      final tasks = <TaskItem>[];
      final taskRaw = value['tasks'];
      if (taskRaw is List) {
        for (final item in taskRaw) {
          final task = TaskItem.tryParse(item);
          if (task != null) tasks.add(task);
        }
      }
      final journal = <JournalEntry>[];
      final journalRaw = value['journal'];
      if (journalRaw is List) {
        for (final item in journalRaw) {
          final entry = JournalEntry.tryParse(item);
          if (entry != null) journal.add(entry);
        }
      }
      final sessionRaw = value['session'];
      final settingsRaw = value['settings'];
      return _Decoded(
        night: value['night'] == true,
        habits: habits,
        tasks: tasks,
        journal: journal,
        session: sessionRaw is Map
            ? Map<String, dynamic>.from(sessionRaw)
            : null,
        settings: settingsRaw is Map
            ? Map<String, dynamic>.from(settingsRaw)
            : null,
      );
    } on FormatException {
      return null;
    }
  }
}

int valueOnSafe(Habit habit, DateTime day) => habit.log[dateKey(day)] ?? 0;

class _Decoded {
  const _Decoded({
    required this.night,
    required this.habits,
    required this.tasks,
    required this.journal,
    required this.session,
    required this.settings,
  });

  final bool night;
  final List<Habit> habits;
  final List<TaskItem> tasks;
  final List<JournalEntry> journal;
  final Map<String, dynamic>? session;
  final Map<String, dynamic>? settings;
}
