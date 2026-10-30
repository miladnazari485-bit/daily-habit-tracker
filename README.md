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

Each habit and each to-do is its own item. Habits are checked per day. To-dos have a due date. A bottom bar stays on every screen: Today, Journal, Calendar, and Settings. Today keeps one week of day pills across the top. The side menu switches every habit between Compact, Weekly, Monthly, and Yearly. Weekly is seven days, Monthly is the weeks of that month, and Yearly is a dense grid of the last 53 weeks. The month grid is on Calendar. A habit that reaches its goal for the selected day leaves Daily Habits and sits in Completed, which opens and closes from its header. Tap a to-do on Today to write a comment; the row stays one line until you tap it. After the first launch, the phone remembers the day, each page, and which habit you had open.

Versions use semantic versioning in `pubspec.yaml` (`MAJOR.MINOR.PATCH+build`) and the same name in `lib/app_version.dart`. Raise PATCH for a fix, MINOR for a new behavior, and the build number on every installable Android file.

## What you can do

- On Today, the To-Do List stays above every daily habit you added. Daily Habits and Completed follow it. A habit moves into Completed on the day it hits its goal.
- The + button opens New Habit. Count is five sideways rows: Fitness, Health, Mind, Chores, and Reduce. The choice is saved on the phone.
- The side menu sets Habit Display to Compact, Weekly, Monthly, or Yearly. That changes the day grid on every habit you created.
- Switch appearance among Day, Color, and Night. Color uses the navy, cyan, and orange from the app icon. Buttons and chips keep a small corner radius.
- Read the Journal for each log, with the time, the habit, and the amount.
- See the week on Calendar as colored blocks for habits and to-dos.
- Use Settings for appearance, week start, font size, archive, export, and a Google address kept on this phone. Sign-in does not contact Google.

The first launch includes Wake Up Early, Drink Water, Training, and an overdue "Buy groceries" task so the board is not empty.

Everything needed to calculate streaks, month rates, and daily progress is stored on the phone with `shared_preferences`. The release app does not request the internet permission and does not call a server.

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

Installable APK (all calculations stay on the phone):

```bash
flutter build apk --release
```

The file is `build/app/outputs/flutter-apk/app-release.apk`. Copy it to the phone and open it. If Android asks, allow installs from your file manager. The release build is signed with the debug key so you can install it directly. Replace that signing setup before you publish on the Play Store.

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
