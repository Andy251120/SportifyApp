import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/friendly_empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rounded_card.dart';
import '../../auth/application/auth_provider.dart';
import '../application/availability_provider.dart';
import '../application/match_request_provider.dart';
import '../data/match_request_model.dart';
import 'matchmaking_ui.dart';

/// Chi tiết 1 kèo — nhánh creator (duyệt người xin vào / xem SĐT) và nhánh
/// responder (xin vào / rút / xem SĐT sau khi được chọn).
class MatchRequestDetailScreen extends ConsumerWidget {
  const MatchRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(requestDetailProvider(requestId));
    final myId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết kèo')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => FriendlyEmptyState(
          emoji: '📡',
          title: 'Không tải được kèo',
          message: 'Mạng chập chờn, thử lại chút nha!',
          action: PrimaryButton(
            label: 'Thử lại',
            onPressed: () {
              ref.invalidate(requestDetailProvider(requestId));
              ref.invalidate(matchedContactProvider(requestId));
            },
          ),
        ),
        data: (req) {
          if (myId == null) return const SizedBox.shrink();
          final isCreator = req.creatorId == myId;
          return RefreshIndicator(
            onRefresh: () {
              ref.invalidate(matchedContactProvider(requestId));
              return ref.refresh(requestDetailProvider(requestId).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _HeaderCard(req: req),
                const SizedBox(height: 16),
                if (isCreator)
                  _CreatorView(req: req, myId: myId)
                else
                  _ResponderView(req: req, myId: myId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.req});
  final MatchRequest req;

  @override
  Widget build(BuildContext context) {
    final title = (req.note?.trim().isNotEmpty ?? false)
        ? req.note!.trim()
        : 'Kèo ${sportLabel(req.sport)}';
    return RoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(sportEmoji(req.sport),
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(prettyRequestDate(req.preferredDate),
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text('Chủ kèo: ${req.creator?.displayName ?? 'Người chơi'}',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Creator
// ---------------------------------------------------------------------------

class _CreatorView extends ConsumerWidget {
  const _CreatorView({required this.req, required this.myId});
  final MatchRequest req;
  final String myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (req.status) {
      case MatchRequestStatus.matched:
        final accepted = req.acceptedResponse;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đã ghép với ${accepted?.responder?.displayName ?? 'đối phương'} 🎉',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            _ContactCard(requestId: req.id),
            const SizedBox(height: 12),
            const Text(
              'Hẹn nhau ra sân rồi vào tab giữa ghi kết quả nhé!',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        );
      case MatchRequestStatus.cancelled:
        return const Text('Kèo này đã huỷ rồi.');
      case MatchRequestStatus.open:
        final pending = req.responses
            .where((r) => r.status == ResponseStatus.pending)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvailabilityHint(
                profileId: myId, sport: req.sport, isMe: true),
            const SizedBox(height: 16),
            const Text('Người xin vào kèo',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chưa ai xin vào kèo. Chờ chút nha!',
                    style: TextStyle(color: AppTheme.textMuted)),
              )
            else
              for (final r in pending)
                _PendingResponderCard(req: req, response: r),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _confirmCancel(context, ref),
              child: const Text('Huỷ kèo'),
            ),
          ],
        );
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ kèo này?'),
        content: const Text('Kèo sẽ biến mất khỏi danh sách. Không khôi phục được.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Thôi')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Huỷ kèo')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await ref.read(myRequestsProvider.notifier).cancel(req.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Đã huỷ kèo.')));
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              const SnackBar(content: Text('Huỷ chưa được, thử lại nha!')));
      }
    }
  }
}

class _PendingResponderCard extends ConsumerStatefulWidget {
  const _PendingResponderCard({required this.req, required this.response});
  final MatchRequest req;
  final MatchRequestResponse response;

  @override
  ConsumerState<_PendingResponderCard> createState() =>
      _PendingResponderCardState();
}

class _PendingResponderCardState
    extends ConsumerState<_PendingResponderCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.response.responder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RoundedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RequestAvatar(
                    name: p?.displayName ?? 'Người chơi',
                    url: p?.avatarUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p?.displayName ?? 'Người chơi',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      if (p?.district != null &&
                          p!.district!.trim().isNotEmpty)
                        Text(p.district!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Chọn người này',
                loading: _busy,
                onPressed: _busy ? null : _accept,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept() async {
    final name = widget.response.responder?.displayName ?? 'người này';
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ghép với $name?'),
        content: const Text('Người khác xin vào kèo sẽ bị từ chối.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Thôi')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Ghép')),
        ],
      ),
    );
    if (sure != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(myRequestsProvider.notifier)
          .accept(widget.response.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content:
                  Text('Đã ghép kèo! Xem SĐT đối phương bên dưới nha.')));
        ref.invalidate(requestDetailProvider(widget.req.id));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Ghép chưa được, thử lại chút nha!')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Responder
// ---------------------------------------------------------------------------

class _ResponderView extends ConsumerStatefulWidget {
  const _ResponderView({required this.req, required this.myId});
  final MatchRequest req;
  final String myId;

  @override
  ConsumerState<_ResponderView> createState() => _ResponderViewState();
}

class _ResponderViewState extends ConsumerState<_ResponderView> {
  bool _busy = false;

  MatchRequest get req => widget.req;

  @override
  Widget build(BuildContext context) {
    final myResp = req.myResponse(widget.myId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvailabilityHint(
            profileId: req.creatorId, sport: req.sport, isMe: false),
        const SizedBox(height: 16),
        switch (myResp?.status) {
          null => SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Xin vào kèo',
                loading: _busy,
                onPressed:
                    (_busy || req.status != MatchRequestStatus.open)
                        ? null
                        : _respond,
              ),
            ),
          ResponseStatus.pending => Row(
              children: [
                const MiniChip(
                    text: '⏳ Đang chờ chủ kèo duyệt',
                    color: AppTheme.tennisBallOrange),
                const Spacer(),
                TextButton(
                  onPressed:
                      _busy ? null : () => _withdraw(myResp!.id),
                  child: const Text('Rút đăng ký'),
                ),
              ],
            ),
          ResponseStatus.accepted => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bạn được chọn! 🎉',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _ContactCard(requestId: req.id),
                const SizedBox(height: 12),
                const Text(
                  'Hẹn nhau ra sân rồi vào tab giữa ghi kết quả nhé!',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ResponseStatus.declined =>
            const Text('Chủ kèo đã chọn người khác rồi 😢'),
        },
      ],
    );
  }

  Future<void> _respond() async {
    setState(() => _busy = true);
    try {
      await ref.read(openRequestsProvider.notifier).respond(req.id);
      if (mounted) {
        _snack('Đã gửi lời xin vào kèo!');
        ref.invalidate(requestDetailProvider(req.id));
      }
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
      if (mounted) {
        _snack('Đã rút đăng ký.');
        ref.invalidate(requestDetailProvider(req.id));
      }
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

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _AvailabilityHint extends ConsumerWidget {
  const _AvailabilityHint({
    required this.profileId,
    required this.sport,
    required this.isMe,
  });

  final String profileId;
  final String sport;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(availabilityForProvider((profileId, sport)));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (slots) {
        if (slots.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe
                    ? 'Bạn chưa đặt khung giờ rảnh'
                    : 'Chủ kèo chưa đặt khung giờ rảnh',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              if (isMe)
                TextButton(
                  onPressed: () => context.push('/availability'),
                  child: const Text('Đặt khung giờ rảnh'),
                ),
            ],
          );
        }
        final text = slots
            .map((s) => '${s.dayLabel} ${s.start}–${s.end}')
            .join(', ');
        return RoundedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe
                    ? 'Khung giờ rảnh của bạn'
                    : 'Khung giờ rảnh của chủ kèo',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(text,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              if (isMe)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.push('/availability'),
                    child: const Text('Sửa khung giờ rảnh'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ContactCard extends ConsumerWidget {
  const _ContactCard({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matchedContactProvider(requestId));
    return async.when(
      loading: () => const RoundedCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => const RoundedCard(
        child: Text('Chưa lấy được thông tin liên hệ. Kéo để tải lại nhé!'),
      ),
      data: (contact) {
        if (contact == null) {
          return const RoundedCard(
            child: Text('Chưa có thông tin liên hệ.'),
          );
        }
        return RoundedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RequestAvatar(
                    name: contact.fullName ?? 'Người chơi',
                    url: contact.avatarUrl,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(contact.fullName ?? 'Người chơi',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.phone,
                      size: 18, color: AppTheme.courtGreen),
                  const SizedBox(width: 8),
                  SelectableText(
                    contact.phone ?? 'Chưa có số điện thoại',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
