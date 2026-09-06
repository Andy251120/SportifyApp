/// Nhãn ngày trong tuần theo quy ước Rally: index 0 = Thứ 2 … 6 = Chủ nhật.
/// Khớp `availability.day_of_week` (SCHEMA.md).
const List<String> kDayLabels = [
  'Thứ 2',
  'Thứ 3',
  'Thứ 4',
  'Thứ 5',
  'Thứ 6',
  'Thứ 7',
  'Chủ nhật',
];

/// Map với row `availability` — 1 khung giờ rảnh của user.
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.sport,
    required this.dayOfWeek,
    required this.start,
    required this.end,
  });

  final String id;
  final String sport; // 'tennis' | 'pickleball'

  /// 0 = Thứ 2 … 6 = Chủ nhật.
  final int dayOfWeek;

  /// Dạng `'HH:mm'`.
  final String start;
  final String end;

  String get dayLabel =>
      (dayOfWeek >= 0 && dayOfWeek < kDayLabels.length) ? kDayLabels[dayOfWeek] : '?';

  String get rangeLabel => '$start–$end';

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
        id: json['id'] as String,
        sport: json['sport'] as String,
        dayOfWeek: (json['day_of_week'] as num).toInt(),
        start: _hhmm(json['start_time'] as String),
        end: _hhmm(json['end_time'] as String),
      );

  /// DB trả `time` dạng `'HH:MM:SS'` → cắt còn `'HH:mm'`.
  static String _hhmm(String raw) => raw.length >= 5 ? raw.substring(0, 5) : raw;
}
