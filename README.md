# Habit Tracker

A Flutter habit tracker. The same project runs on Windows, Android, iOS, and the web.

## Open it on Windows in VS Code

1. Install [Flutter for Windows](https://docs.flutter.dev/get-started/install/windows).
2. Install [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/) with the **Desktop development with C++** workload. `flutter run -d windows` needs that compiler.
3. Unzip `habit-tracker-windows.zip`.
4. In VS Code, choose **File → Open Folder** and select the unzipped folder. Install the Flutter and Dart extensions when VS Code offers them.

Then, in the VS Code terminal:

```bat
flutter pub get
flutter run -d windows
```

Or double-click `run.bat` in the project folder. That runs those two commands for you.

To start it from the debugger, press **F5** and pick **Habit Tracker (Windows)**.

If the Windows desktop toolchain is not installed yet, this still runs in Chrome:

```bat
flutter run -d chrome
```

Check what is missing with:

```bat
flutter doctor
```

Each habit and each task is its own item. Habits are checked per day. Tasks are one-off, with a due date. A bottom bar stays on every screen. The first screen opens on today, with that month's days in a strip you can scroll.

## What you can do

- Scroll the days of a month and tap one to see that day's checks. Opening the app lands on today.
- Log a habit for the day you are viewing. Once-a-day habits toggle. Counted habits add a unit. Large goals, like steps, open a logger.
- Open a habit to check or edit any past day on its own calendar.
- Keep tasks separate from habits. Overdue tasks can be postponed or checked off.
- Switch between day mood and night mood. The choice is saved on the device.
- Review the month on the calendar and streaks on Insights.

The first launch includes Wake Up Early, Drink Water, Training, and an overdue "Buy groceries" task so the board is not empty. Anything you change is stored on the device with `shared_preferences`.

## Run it

Install [Flutter](https://docs.flutter.dev/get-started/install) 3.35 or newer. This project was built with Flutter 3.47.

```bash
flutter pub get
```

Web preview:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 47291
```

Then open `http://127.0.0.1:47291`.

Android (device or emulator):

```bash
flutter run -d android
```

iOS (macOS with Xcode):

```bash
flutter run -d ios
```

You can also open `android/` in Android Studio, or `ios/Runner.xcworkspace` in Xcode. The UI is shared, so a change on one platform shows up on the other.

## Tests

```bash
flutter test
```

## Layout

- `lib/screens` — Today, Tasks, Calendar, Insights, and the per-habit day view
- `lib/state/app_state.dart` — the board and the on-device save
- `lib/models` — `Habit` and `TaskItem`
- `lib/logic` — dates, streaks, and per-day progress
