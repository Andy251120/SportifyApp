import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/friendly_empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rounded_card.dart';
import '../../auth/application/auth_provider.dart';
import '../application/match_provider.dart';
import '../data/match_model.dart';

/// "Trận đấu của tôi" — trận cần xác nhận + lịch sử gần đây.
class ConfirmResultScreen extends ConsumerWidget {
  const ConfirmResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentUserProvider)?.id;
    final async = ref.watch(myMatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trận đấu của tôi')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => FriendlyEmptyState(
          emoji: '📡',
          title: 'Không tải được',
          message: 'Thử lại nhé!',
          action: PrimaryButton(
            label: 'Thử lại',
            onPressed: () => ref.read(myMatchesProvider.notifier).refresh(),
          ),
        ),
        data: (matches) {
          if (myId == null) return const SizedBox.shrink();

          final needsMe = matches.where((m) => m.canConfirm(myId)).toList();
          final others = matches.where((m) => !m.canConfirm(myId)).toList();

          if (matches.isEmpty) {
            return const FriendlyEmptyState(
              emoji: '🎾',
              title: 'Chưa có trận nào',
              message: 'Ghi kết quả trận đầu tiên để bắt đầu leo hạng nhé!',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(myMatchesProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (needsMe.isNotEmpty) ...[
                  const _SectionTitle('Cần bạn xác nhận'),
                  for (final m in needsMe) _MatchCard(match: m, myId: myId, actionable: true),
                  const SizedBox(height: 12),
                ],
                const _SectionTitle('Trận gần đây'),
                if (others.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Chưa có trận nào khác.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                for (final m in others) _MatchCard(match: m, myId: myId, actionable: false),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match, required this.myId, required this.actionable});

  final MatchSummary match;
  final String myId;
  final bool actionable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySide = match.me(myId)?.side;
    final opponents = match.participants.where((p) => p.side != mySide).toList();
    final opponentNames = opponents.isEmpty
        ? 'Chưa rõ đối thủ'
        : opponents.map((p) => p.profile?.displayName ?? 'Người chơi').join(' & ');
    final scoreText = match.score.map((s) => '${s.a}-${s.b}').join(', ');
    final myParticipant = match.me(myId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: RoundedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(match.sport == 'pickleball' ? '🏓' : '🎾', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('vs $opponentNames',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                _StatusChip(match: match, myId: myId),
              ],
            ),
            const SizedBox(height: 8),
            Text(scoreText.isEmpty ? 'Chưa có tỷ số' : scoreText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (match.status == MatchStatus.confirmed && myParticipant?.ratingAfter != null) ...[
              const SizedBox(height: 4),
              Text('Điểm trình mới: ${myParticipant!.ratingAfter!.round()}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
            if (actionable) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmDispute(context, ref, match.id),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Xác nhận',
                      onPressed: () => ref.read(myMatchesProvider.notifier).confirm(match.id),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDispute(BuildContext context, WidgetRef ref, String matchId) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối kết quả này?'),
        content: const Text('Trận sẽ chuyển sang trạng thái tranh chấp, điểm trình không đổi.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Thôi')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Từ chối')),
        ],
      ),
    );
    if (sure == true) {
      await ref.read(myMatchesProvider.notifier).dispute(matchId);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.match, required this.myId});
  final MatchSummary match;
  final String myId;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (match.status) {
      MatchStatus.confirmed => ('✅ Đã xác nhận', AppTheme.courtGreen),
      MatchStatus.disputed => ('❗ Tranh chấp', Colors.redAccent),
      MatchStatus.cancelled => ('Đã huỷ', AppTheme.textMuted),
      MatchStatus.pendingConfirmation =>
        match.isReporter(myId) ? ('⏳ Chờ đối thủ', AppTheme.textMuted) : ('Cần xác nhận', AppTheme.tennisBallOrange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
