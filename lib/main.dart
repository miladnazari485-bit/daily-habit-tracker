import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scope.dart';

/// Starts the app, loads the saved board, and paints edge to edge.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final state = AppState();
  await state.load();
  runApp(HabitTrackerApp(state: state));
}

/// Root widget. Holds [AppState] and switches day and night from settings.
class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key, required this.state});

  final AppState state;

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  String? _appearance;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onState);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (_appearance != widget.state.appearance) {
      setState(() => _appearance = widget.state.appearance);
    }
  }

  @override
  Widget build(BuildContext context) {
    _appearance = widget.state.appearance;
    final colorMode = _appearance == 'color';
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'Habit Tracker',
        debugShowCheckedModeBanner: false,
        theme: colorMode ? buildColorTheme() : buildLightTheme(),
        darkTheme: colorMode ? buildColorTheme() : buildDarkTheme(),
        themeMode: colorMode ? ThemeMode.light : widget.state.themeMode,
        themeAnimationDuration: const Duration(milliseconds: 250),
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, child) {
          final scale = widget.state.fontScale;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                scale * MediaQuery.textScalerOf(context).scale(1),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const ResponsiveFrame(child: Shell()),
      ),
    );
  }
}

/// On a wide browser window the app sits in a phone-sized frame. On a phone
/// it fills the screen, which is how Android and iOS will show it.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) return child;
        final colors = AppColors.of(context);
        final height = math.min(constraints.maxHeight - 48, 880.0);
        return ColoredBox(
          color: colors.canvas,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.scaffold,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: colors.ink.withValues(alpha: 0.14),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: SizedBox(width: 400, height: height, child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
