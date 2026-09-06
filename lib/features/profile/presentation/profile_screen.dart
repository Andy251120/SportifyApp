import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/da_nang.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/friendly_empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/profile_provider.dart';
import '../data/profile_model.dart';
import 'show_off_radar_chart.dart';
import 'skill_rating_editor.dart';
import 'sport_tab_switcher.dart';

/// Màn Hồ sơ chính — implement theo UI_SPEC.md.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProfileProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => FriendlyEmptyState(
        emoji: '📡',
        title: 'Mạng đang chập chờn',
        message: 'Không tải được hồ sơ. Thử lại nhé!',
        action: PrimaryButton(
          label: 'Thử lại',
          onPressed: () => ref.read(myProfileProvider.notifier).refresh(),
        ),
      ),
      data: (profile) => profile == null
          ? const Center(child: Text('Chưa có hồ sơ.'))
          : _ProfileBody(profile: profile),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sport = ref.watch(viewedSportProvider);
    final stats = profile.statsFor(sport);

    return RefreshIndicator(
      onRefresh: () => ref.read(myProfileProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        children: [
          _Header(profile: profile),
          const SizedBox(height: 20),
          SportTabSwitcher(
            value: sport,
            onChanged: (s) => ref.read(viewedSportProvider.notifier).set(s),
          ),
          const SizedBox(height: 20),
          if (stats == null)
            _EmptySportState(sport: sport)
          else ...[
            _RatingBlock(stats: stats, isVerified: profile.isVerified),
            SizedBox(
              height: 220,
              child: ShowOffRadarChart(
                matrix: stats.skillMatrix,
                color: AppTheme.radarColor(sport.dbValue),
              ),
            ),
            const SizedBox(height: 16),
            const _ShareProfileButton(),
          ],
        ],
      ),
    );
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  bool _uploading = false;

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      await ref.read(myProfileProvider.notifier).uploadAvatar(bytes, ext);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Đổi ảnh chưa được — kiểm tra lại kết nối nhé!'),
          ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Row(
      children: [
        GestureDetector(
          onTap: _uploading ? null : _pickAvatar,
          child: SizedBox(
            width: 52,
            height: 52,
            child: _uploading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.tennisBallOrange,
                    foregroundImage: p.avatarUrl != null
                        ? NetworkImage(p.avatarUrl!)
                        : null,
                    child: Text(
                      p.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.fullName ?? 'Bạn chơi thể thao',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                p.locationDistrict ?? 'Chưa rõ khu vực',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingBlock extends StatelessWidget {
  const _RatingBlock({required this.stats, required this.isVerified});
  final SportStats stats;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              stats.rating.round().toString(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isVerified ? 'điểm trình' : 'điểm trình · chưa xác thực',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${stats.matchesPlayed} trận đã đấu',
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ShareProfileButton extends StatelessWidget {
  const _ShareProfileButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO(Phase sau): xuất card hồ sơ dạng ảnh để chia sẻ (SRS 5.5).
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Tính năng chia sẻ hồ sơ sẽ có ở bản sau nha!'),
            ));
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.borderSubtle),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: AppTheme.textPrimary,
        ),
        icon: const Icon(Icons.share, size: 18),
        label: const Text(
          'Chia sẻ hồ sơ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _EmptySportState extends ConsumerWidget {
  const _EmptySportState({required this.sport});
  final SportType sport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FriendlyEmptyState(
      emoji: sport == SportType.tennis ? '🎾' : '🏓',
      title: 'Chưa có điểm trình ${sport.label}',
      message:
          'Bạn chưa có điểm trình ${sport.label} — tự đánh giá ngay để bắt đầu leo hạng nhé!',
      action: PrimaryButton(
        label: 'Tự đánh giá ngay',
        icon: Icons.auto_graph,
        onPressed: () => showSelfRateSheet(context, ref, sport),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheets — gọi được từ HomeShell (menu AppBar) và trong màn này.
// ---------------------------------------------------------------------------

/// Tự đánh giá điểm trình cho 1 môn chưa mở (dùng lại UI onboarding bước 3).
Future<void> showSelfRateSheet(
    BuildContext context, WidgetRef ref, SportType sport) {
  return _skillSheet(
    context,
    title: 'Tự đánh giá điểm trình ${sport.label}',
    initial: const SkillMatrix.filled(50),
    color: AppTheme.radarColor(sport.dbValue),
    onSave: (m) =>
        ref.read(myProfileProvider.notifier).addSport(sport, m),
  );
}

/// Chỉnh lại điểm Show-off của môn đã mở.
Future<void> showEditSkillSheet(
    BuildContext context, WidgetRef ref, SportType sport, SkillMatrix current) {
  return _skillSheet(
    context,
    title: 'Chỉnh điểm Show-off ${sport.label}',
    initial: current,
    color: AppTheme.radarColor(sport.dbValue),
    onSave: (m) =>
        ref.read(myProfileProvider.notifier).updateSkillMatrix(sport, m),
  );
}

Future<void> _skillSheet(
  BuildContext context, {
  required String title,
  required SkillMatrix initial,
  required Color color,
  required Future<void> Function(SkillMatrix) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: _SkillSheet(
          title: title, initial: initial, color: color, onSave: onSave),
    ),
  );
}

class _SkillSheet extends StatefulWidget {
  const _SkillSheet({
    required this.title,
    required this.initial,
    required this.color,
    required this.onSave,
  });

  final String title;
  final SkillMatrix initial;
  final Color color;
  final Future<void> Function(SkillMatrix) onSave;

  @override
  State<_SkillSheet> createState() => _SkillSheetState();
}

class _SkillSheetState extends State<_SkillSheet> {
  late SkillMatrix _matrix = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SkillRatingEditor(
            value: _matrix,
            color: widget.color,
            onChanged: (m) => setState(() => _matrix = m),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Lưu',
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.onSave(_matrix);
            },
          ),
        ],
      ),
    );
  }
}

/// Sửa tên + khu vực (mở từ menu AppBar).
Future<void> showEditBasicsSheet(BuildContext context, WidgetRef ref) {
  final p = ref.read(myProfileProvider).valueOrNull;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: _EditBasicsSheet(
        initialName: p?.fullName ?? '',
        initialDistrict: p?.locationDistrict,
        onSave: (name, district) =>
            ref.read(myProfileProvider.notifier).updateBasics(
                  fullName: name,
                  district: district,
                ),
      ),
    ),
  );
}

class _EditBasicsSheet extends StatefulWidget {
  const _EditBasicsSheet({
    required this.initialName,
    required this.initialDistrict,
    required this.onSave,
  });

  final String initialName;
  final String? initialDistrict;
  final Future<void> Function(String? name, String? district) onSave;

  @override
  State<_EditBasicsSheet> createState() => _EditBasicsSheetState();
}

class _EditBasicsSheetState extends State<_EditBasicsSheet> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.initialName);
  late String? _district = widget.initialDistrict;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sửa tên / khu vực',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(hintText: 'Tên hoặc biệt danh'),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in kDaNangDistricts)
              ChoiceChip(
                label: Text(d),
                selected: _district == d,
                onSelected: (_) => setState(() => _district = d),
              ),
          ],
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Lưu',
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            Navigator.of(context).pop();
            await widget.onSave(name.isEmpty ? null : name, _district);
          },
        ),
      ],
    );
  }
}
