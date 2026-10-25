import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_scope.dart';

/// Opens the stopwatch or countdown chosen in Settings.
Future<void> showTimerSheet(BuildContext context) {
  final colors = AppColors.of(context);
  final countdown = AppScope.of(context).timerDefault == 'countdown';
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.zero),
    ),
    builder: (context) => _TimerSheet(countdown: countdown),
  );
}

class _TimerSheet extends StatefulWidget {
  const _TimerSheet({required this.countdown});

  final bool countdown;

  @override
  State<_TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<_TimerSheet> {
  static const _countdownSeconds = 25 * 60;
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Starts the clock and ticks the label once a second.
  void _start() {
    _watch.start();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _watch.elapsed.inSeconds);
      if (widget.countdown && _elapsed >= _countdownSeconds) {
        _watch.stop();
        _ticker?.cancel();
        _ticker = null;
      }
    });
    setState(() {});
  }

  /// Stops the clock without clearing the elapsed time.
  void _pause() {
    _watch.stop();
    _ticker?.cancel();
    _ticker = null;
    setState(() {});
  }

  /// Clears the clock back to zero.
  void _reset() {
    _watch
      ..stop()
      ..reset();
    _ticker?.cancel();
    _ticker = null;
    setState(() => _elapsed = 0);
  }

  /// Formats seconds as `mm:ss`.
  String _clock(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final rest = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final remaining = _countdownSeconds - _elapsed;
    final label = widget.countdown ? _clock(remaining) : _clock(_elapsed);
    final running = _watch.isRunning;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.countdown ? 'Countdown' : 'Stopwatch',
              style: TextStyle(
                color: colors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.ink,
                fontSize: 56,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The timer stays on this phone and is not saved.',
              style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: running ? _pause : _start,
                    child: Text(running ? 'Pause' : 'Start'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
