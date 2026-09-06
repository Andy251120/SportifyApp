import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/friendly_empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rounded_card.dart';
import '../../auth/application/auth_provider.dart';
import '../application/match_request_provider.dart';
import '../data/match_request_model.dart';
import 'matchmaking_ui.dart';

/// "Ghép kèo" — body không Scaffold (HomeShell cấp Scaffold + AppBar).
/// Lọc theo môn + hai mục: "Kèo của tôi" và "Kèo đang mở".
class MatchRequestListScreen extends ConsumerWidget {
  const MatchRequestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentUserProvider)?.id;
    final sport = ref.watch(matchmakingSportProvider);
    final mine = ref.watch(myRequestsProvider);
    final open = ref.watch(openRequestsProvider);
    final responded = ref.watch(respondedRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(openRequestsProvider.notifier).refresh(),
          ref.read(myRequestsProvider.notifier).refresh(),
          ref.read(respondedRequestsProvider.notifier).refresh(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              for (final s in const ['tennis', 'pickleball'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${sportEmoji(s)} ${sportLabel(s)}'),
                    selected: sport == s,
                    selectedColor:
                        AppTheme.sportColor(s).withValues(alpha: 0.18),
                    onSelected: (_) =>
                        ref.read(matchmakingSportProvider.notifier).set(s),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Đăng kèo mới',
            icon: Icons.add,
            onPressed: () => context.push('/matchmaking/create'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Kèo của tôi'),
          mine.when(
            skipLoadingOnReload: true,
            loading: () => const _InlineLoading(),
            error: (_, __) => const _InlineError(),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Bạn chưa đăng kèo nào. Tạo một cái rủ người ta đi bạn ơi!',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                );
              }
              return Column(
                children: [for (final m in list) _MyRequestCard(request: m)],
              );
            },
          ),
          responded.when(
            skipLoadingOnReload: true,
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              final visible = myId == null
                  ? const <MatchRequest>[]
                  : visibleRespondedRequests(list, myId);
              if (visible.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const _SectionTitle('Kèo tôi đã xin vào'),
                  for (final m in visible)
                    _RespondedCard(request: m, myId: myId),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Kèo đang mở'),
          open.when(
            skipLoadingOnReload: true,
            loading: () => const _InlineLoading(),
            error: (_, __) => const _InlineError(),
            data: (list) {
              if (list.isEmpty) {
                return const FriendlyEmptyState(
                  emoji: '🤝',
                  title: 'Chưa có kèo nào đang mở',
                  message:
                      'Chưa có kèo nào đang mở — đăng một cái rủ người ta đi bạn ơi!',
                );
              }
              return Column(
                children: [
                  for (final m in list) _OpenRequestCard(request: m, myId: myId),
                ],
              );
            },
          ),
        ],
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
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Mạng chập chờn, kéo xuống để thử lại nhé!',
            style: TextStyle(color: AppTheme.textMuted)),
      );
}

class _MyRequestCard extends StatelessWidget {
  const _MyRequestCard({required this.request});
  final MatchRequest request;

  @override
  Widget build(BuildContext context) {
    final m = request;
    final title = (m.note?.trim().isNotEmpty ?? false)
        ? m.note!.trim()
        : 'Kèo ${sportLabel(m.sport)}';
    final (statusText, statusColor) = switch (m.status) {
      MatchRequestStatus.open => ('Đang mở', AppTheme.tennisBallOrange),
      MatchRequestStatus.matched => ('Đã ghép', AppTheme.courtGreen),
      MatchRequestStatus.cancelled => ('Đã huỷ', AppTheme.textMuted),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RoundedCard(
        onTap: () => context.push('/matchmaking/${m.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(sportEmoji(m.sport), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                MiniChip(text: statusText, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(prettyRequestDate(m.preferredDate),
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              m.status == MatchRequestStatus.matched
                  ? '✅ Đã ghép'
                  : '${m.pendingCount} người xin vào',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card cho "Kèo tôi đã xin vào" — chỉ hiển thị + điều hướng, không có action
/// (respond/withdraw nằm ở màn chi tiết / card "Kèo đang mở").
class _RespondedCard extends StatelessWidget {
  const _RespondedCard({required this.request, required this.myId});
  final MatchRequest request;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final m = request;
    final creator = m.creator;
    final uid = myId;
    final myResp = uid == null ? null : m.myResponse(uid);
    final (statusText, statusColor) = switch (myResp?.status) {
      ResponseStatus.accepted => (
          '✅ Đã ghép — xem SĐT',
          AppTheme.courtGreen,
        ),
      ResponseStatus.declined => (
          'Chủ kèo chọn người khác rồi',
          AppTheme.textMuted,
        ),
      _ => ('⏳ Chờ chủ kèo duyệt', AppTheme.tennisBallOrange),
    };
    final subtitle = [
      creator?.displayName ?? 'Người chơi',
      if (creator?.district != null && creator!.district!.trim().isNotEmpty)
        creator.district!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RoundedCard(
        onTap: () => context.push('/matchmaking/${m.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(sportEmoji(m.sport), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (m.note?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text(m.note!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 10),
            MiniChip(text: statusText, color: statusColor),
          ],
        ),
      ),
    );
  }
}

class _OpenRequestCard extends ConsumerStatefulWidget {
  const _OpenRequestCard({required this.request, required this.myId});
  final MatchRequest request;
  final String? myId;

  @override
  ConsumerState<_OpenRequestCard> createState() => _OpenRequestCardState();
}

class _OpenRequestCardState extends ConsumerState<_OpenRequestCard> {
  bool _busy = false;

  MatchRequest get m => widget.request;

  @override
  Widget build(BuildContext context) {
    final myId = widget.myId;
    final myResp = myId == null ? null : m.myResponse(myId);
    final creator = m.creator;
    final ratingText = m.creatorRating != null
        ? '~${m.creatorRating!.round()} điểm'
        : 'chưa có điểm trình';
    final subtitle = [
      if (creator?.district != null && creator!.district!.trim().isNotEmpty)
        creator.district!,
      ratingText,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RoundedCard(
        onTap: myResp?.status == ResponseStatus.accepted
            ? () => context.push('/matchmaking/${m.id}')
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RequestAvatar(
                  name: creator?.displayName ?? 'Người chơi',
                  url: creator?.avatarUrl,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(creator?.displayName ?? 'Người chơi',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Text(sportEmoji(m.sport),
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
            if (m.note?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(m.note!.trim(), style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 4),
            Text(prettyRequestDate(m.preferredDate),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            _action(myResp),
          ],
        ),
      ),
    );
  }

  Widget _action(MatchRequestResponse? myResp) {
    switch (myResp?.status) {
      case null:
        return SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Xin vào kèo',
            loading: _busy,
            onPressed: _busy ? null : _respond,
          ),
        );
      case ResponseStatus.pending:
        return Row(
          children: [
            const MiniChip(
                text: '⏳ Chờ chủ kèo duyệt',
                color: AppTheme.tennisBallOrange),
            const Spacer(),
            TextButton(
              onPressed: _busy ? null : () => _withdraw(myResp!.id),
              child: const Text('Rút'),
            ),
          ],
        );
      case ResponseStatus.declined:
        return const MiniChip(
            text: 'Chủ kèo chọn người khác rồi', color: AppTheme.textMuted);
      case ResponseStatus.accepted:
        return const MiniChip(
            text: '✅ Được chọn!', color: AppTheme.courtGreen);
    }
  }

  Future<void> _respond() async {
    setState(() => _busy = true);
    try {
      await ref.read(openRequestsProvider.notifier).respond(m.id);
      if (mounted) _snack('Đã gửi lời xin vào kèo! Chờ chủ kèo duyệt nha.');
    } catch (_) {
      if (mounted) _snack('Xin vào kèo chưa được, thử lại chút nha!');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw(String responseId) async {
    setState(() => _busy = true);
    try {
      await ref.read(openRequestsProvider.notifier).withdraw(responseId);
      if (mounted) _snack('Đã rút khỏi kèo.');
    } catch (_) {
      if (mounted) _snack('Rút chưa được, thử lại chút nha!');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}
