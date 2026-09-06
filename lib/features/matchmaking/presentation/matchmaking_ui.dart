import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

/// Emoji của môn dùng chung cho các card ghép kèo.
String sportEmoji(String sport) => sport == 'pickleball' ? '🏓' : '🎾';

/// Nhãn tiếng Việt của môn.
String sportLabel(String sport) => sport == 'pickleball' ? 'Pickleball' : 'Tennis';

/// Ngày kèo dạng thân thiện: "Hôm nay" / "Ngày mai" / "dd/MM" / "Chưa chọn ngày".
String prettyRequestDate(DateTime? date) {
  if (date == null) return 'Chưa chọn ngày';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Ngày mai';
  return DateFormat('dd/MM').format(date);
}

/// Avatar tròn cho người chơi — ảnh có cache, fallback initials.
class RequestAvatar extends StatelessWidget {
  const RequestAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 22,
  });

  final String name;
  final String? url;
  final double radius;

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.take(2).map((w) => w[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.tennisBallOrange,
      foregroundImage: (url != null && url!.isNotEmpty)
          ? CachedNetworkImageProvider(url!)
          : null,
      child: Text(
        _initials,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Chip trạng thái nhỏ dạng pill — dùng lại pattern `_StatusChip` của matches.
class MiniChip extends StatelessWidget {
  const MiniChip({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
