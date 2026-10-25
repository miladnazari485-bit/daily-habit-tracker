import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';

/// Day cells inside one habit on Today.
///
/// Weekly is one row of seven days. Monthly is that month, seven columns
/// by the weeks it touches. Yearly is the last 53 weeks, with weekdays
/// stacked so the current week is the last column.
class HabitSpanGrid extends StatelessWidget {
  const HabitSpanGrid({
    super.key,
    required this.habit,
    required this.anchor,
    required this.weekStart,
    required this.display,
  });

  final Habit habit;
  final DateTime anchor;
  final int weekStart;

  /// `week`, `month`, or `year`. Compact does not build this widget.
  final String display;

  @override
  Widget build(BuildContext context) {
    final days = _days();
    final columns = display == 'year' ? 53 : 7;
    final rows = days.length ~/ columns;
    final colors = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = display == 'year' ? 1.5 : 3.0;
        final width = constraints.maxWidth;
        final cellW = (width - gap * (columns - 1)) / columns;
        final cellH = display == 'year'
            ? cellW
            : display == 'week'
            ? 24.0
            : 16.0;
        final ratios = <double>[
          for (final day in days)
            day == null ? -1 : ratioOn(habit, day),
        ];
        return SizedBox(
          key: ValueKey('habit-grid-$display'),
          height: rows * cellH + gap * (rows - 1),
          width: width,
          child: CustomPaint(
            painter: _SpanPainter(
              ratios: ratios,
              columns: columns,
              color: Color(habit.colorValue),
              empty: colors.chip,
              gap: gap,
              cellH: cellH,
              dark: dark,
              byHeight: display != 'year',
            ),
          ),
        );
      },
    );
  }

  /// Days in row-major order. A null day is padding outside the month.
  List<DateTime?> _days() {
    final day = dateOnly(anchor);
    if (display == 'week') {
      final start = startOfWeek(day, weekStart: weekStart);
      return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    }
    if (display == 'month') {
      final firstOfMonth = DateTime(day.year, day.month);
      final lastOfMonth = DateTime(day.year, day.month, daysInMonth(day.year, day.month));
      final start = startOfWeek(firstOfMonth, weekStart: weekStart);
      final end = startOfWeek(lastOfMonth, weekStart: weekStart).add(const Duration(days: 6));
      final days = <DateTime?>[];
      for (var cursor = start; !cursor.isAfter(end); cursor = cursor.add(const Duration(days: 1))) {
        days.add(cursor.month == day.month ? cursor : null);
      }
      return days;
    }
    final endWeek = startOfWeek(day, weekStart: weekStart);
    final firstWeek = endWeek.subtract(const Duration(days: 7 * 52));
    final days = <DateTime?>[];
    for (var row = 0; row < 7; row++) {
      for (var column = 0; column < 53; column++) {
        days.add(firstWeek.add(Duration(days: column * 7 + row)));
      }
    }
    return days;
  }
}

class _SpanPainter extends CustomPainter {
  const _SpanPainter({
    required this.ratios,
    required this.columns,
    required this.color,
    required this.empty,
    required this.gap,
    required this.cellH,
    required this.dark,
    required this.byHeight,
  });

  final List<double> ratios;
  final int columns;
  final Color color;
  final Color empty;
  final double gap;
  final double cellH;
  final bool dark;
  final bool byHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns <= 0 || ratios.isEmpty) return;
    final cellW = (size.width - gap * (columns - 1)) / columns;
    final radius = Radius.circular((cellW * 0.22).clamp(1.2, 4));
    final paint = Paint()..isAntiAlias = true;
    for (var index = 0; index < ratios.length; index++) {
      final row = index ~/ columns;
      final column = index % columns;
      final rect = Rect.fromLTWH(
        column * (cellW + gap),
        row * (cellH + gap),
        cellW,
        cellH,
      );
      final ratio = ratios[index];
      final track = ratio < 0
          ? empty.withValues(alpha: dark ? 0.28 : 0.4)
          : empty.withValues(alpha: dark ? 0.9 : 1);
      paint.color = track;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
      if (ratio <= 0) continue;
      final tone = ratio.clamp(0.0, 1.0);
      if (byHeight) {
        final fill = Rect.fromLTWH(
          rect.left,
          rect.bottom - rect.height * (tone < 0.12 ? 0.12 : tone),
          rect.width,
          rect.height * (tone < 0.12 ? 0.12 : tone),
        );
        paint.color = color.withValues(alpha: dark ? 0.92 : 0.88);
        canvas.drawRRect(RRect.fromRectAndRadius(fill, radius), paint);
      } else {
        final start = color.withValues(alpha: dark ? 0.35 : 0.4);
        paint.color = Color.lerp(start, color, 0.25 + 0.75 * tone)!;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SpanPainter oldDelegate) {
    return oldDelegate.ratios != ratios ||
        oldDelegate.columns != columns ||
        oldDelegate.color != color ||
        oldDelegate.dark != dark ||
        oldDelegate.byHeight != byHeight;
  }
}
