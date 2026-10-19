import '../logic/dates.dart';

/// One line in the journal. A habit log and a free note share this shape.
class JournalEntry {
  JournalEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.unit,
    required DateTime at,
    required this.colorValue,
    this.habitId,
  }) : at = DateTime(at.year, at.month, at.day, at.hour, at.minute);

  final String id;
  final String? habitId;
  final String title;
  final int amount;
  final String unit;
  final DateTime at;
  final int colorValue;

  /// Map written into the on-device snapshot.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'title': title,
      'amount': amount,
      'unit': unit,
      'at': at.toIso8601String(),
      'color': colorValue,
    };
  }

  /// Builds a journal line from stored JSON, or null when it is incomplete.
  static JournalEntry? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    final amount = raw['amount'];
    final unit = raw['unit'];
    final atRaw = raw['at'];
    final color = raw['color'];
    if (id is! String || title is! String || title.trim().isEmpty) return null;
    if (amount is! num || unit is! String || atRaw is! String) return null;
    if (color is! num) return null;
    final at = DateTime.tryParse(atRaw);
    if (at == null) return null;
    final habitId = raw['habitId'];
    return JournalEntry(
      id: id,
      habitId: habitId is String && habitId.isNotEmpty ? habitId : null,
      title: title.trim(),
      amount: amount.round().clamp(0, 1000000),
      unit: unit.trim().isEmpty ? 'time' : unit.trim(),
      at: at,
      colorValue: color.round(),
    );
  }
}

/// Clock label for a journal row, such as `Oct 19, 08:26`.
String journalWhen(DateTime at) {
  final hour = at.hour.toString().padLeft(2, '0');
  final minute = at.minute.toString().padLeft(2, '0');
  return '${shortMonthDay(at)}, $hour:$minute';
}
