import 'package:flutter/material.dart';

/// Empty state với giọng văn vui vẻ, xưng "bạn" — theo Design direction.
/// Không bao giờ hiện "Không có dữ liệu".
class FriendlyEmptyState extends StatelessWidget {
  const FriendlyEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.message,
    this.action,
  });

  final String emoji;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
