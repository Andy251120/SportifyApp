import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/da_nang.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/friendly_empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rounded_card.dart';
import '../../auth/application/auth_provider.dart';
import '../application/profile_provider.dart';
import '../data/profile_model.dart';
import 'show_off_radar_chart.dart';
import 'skill_rating_editor.dart';
import 'sport_tab_switcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProfileProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.read(myProfileProvider.notifier).refresh(),
      ),
      data: (profile) {
        if (profile == null) {
          return const Center(child: Text('Chưa có hồ sơ.'));
        }
        return _ProfileBody(profile: profile);
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FriendlyEmptyState(
      emoji: '📡',
      title: 'Mạng đang chậpp chờn',
      message: 'Không tải được hồ sơ. Thử lại nhé!',
      action: PrimaryButton(label: 'Thử lại', onPressed: onRetry),
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
    final sportColor = AppTheme.sportColor(sport.dbValue);

    return RefreshIndicator(
      onRefresh: () => ref.read(myProfileProvider.notifier).refresh(),
      child: ListView(
        // Chừa chỗ cho FAB + bottom bar của HomeShell.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _Header(profile: profile),
          const SizedBox(height: 16),
          SportTabSwitcher(
            value: sport,
            onChanged: (s) => ref.read(viewedSportProvider.notifier).set(s),
          ),
          const SizedBox(height: 16),
          if (stats == null)
            _SportNotOpened(sport: sport)
          else
            _SportSection(stats: stats, color: sportColor),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
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

    return RoundedCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.courtGreen.withValues(alpha: 0.15),
                backgroundImage:
                    p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                child: p.avatarUrl == null
                    ? Text(p.displayInitial,
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold))
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: AppTheme.courtGreen,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _uploading ? null : _pickAvatar,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  p.fullName ?? 'Bạn chơi thể thao',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (p.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: AppTheme.courtGreen, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              if (p.locationDistrict != null)
                _Chip(icon: Icons.place_outlined, text: p.locationDistrict!),
              _Chip(icon: Icons.shield_outlined, text: 'Uy tín ${p.trustScore}'),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _editBasics(context, ref, p),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Sửa tên / quận'),
          ),
        ],
      ),
    );
  }
}

Future<void> _editBasics(BuildContext context, WidgetRef ref, Profile p) async {
  final nameCtrl = TextEditingController(text: p.fullName ?? '');
  var district = p.locationDistrict;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sửa thông tin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
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
                    selected: district == d,
                    onSelected: (_) => setSheet(() => district = d),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Lưu',
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(myProfileProvider.notifier).updateBasics(
                      fullName: nameCtrl.text.trim().isEmpty
                          ? null
                          : nameCtrl.text.trim(),
                      district: district,
                    );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SportSection extends ConsumerWidget {
  const _SportSection({required this.stats, required this.color});
  final SportStats stats;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoundedCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Show-off',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _editSkill(context, ref, stats, color),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Chỉnh điểm'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: ShowOffRadarChart(matrix: stats.skillMatrix, color: color),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Điểm trình',
                  value: stats.hasRating
                      ? stats.rating.toStringAsFixed(0)
                      : '—',
                  hint: stats.hasRating ? null : 'chờ trận đầu tiên',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Số trận',
                  value: '${stats.matchesPlayed}',
                ),
              ),
            ],
          ),
          if (stats.titles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in stats.titles)
                  Chip(label: Text(t), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54)),
        if (hint != null)
          Text(hint!,
              style: const TextStyle(fontSize: 11, color: Colors.black38)),
      ],
    );
  }
}

class _SportNotOpened extends ConsumerWidget {
  const _SportNotOpened({required this.sport});
  final SportType sport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoundedCard(
      padding: const EdgeInsets.all(20),
      child: FriendlyEmptyState(
        emoji: sport == SportType.tennis ? '🎾' : '🏓',
        title: 'Chưa mở môn ${sport.label}',
        message: 'Bạn có chơi ${sport.label} không? Mở ra để khoe điểm trình nè!',
        action: PrimaryButton(
          label: 'Mở môn ${sport.label}',
          icon: Icons.add,
          onPressed: () => _openSport(context, ref, sport),
        ),
      ),
    );
  }
}

Future<void> _openSport(
    BuildContext context, WidgetRef ref, SportType sport) async {
  var matrix = const SkillMatrix.filled(5);
  final color = AppTheme.sportColor(sport.dbValue);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tự chấm điểm trình ${sport.label}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SkillRatingEditor(
                value: matrix,
                color: color,
                onChanged: (m) => setSheet(() => matrix = m),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Mở môn ${sport.label}',
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await ref
                      .read(myProfileProvider.notifier)
                      .addSport(sport, matrix);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _editSkill(
    BuildContext context, WidgetRef ref, SportStats stats, Color color) async {
  var matrix = stats.skillMatrix;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Chỉnh điểm Show-off',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SkillRatingEditor(
                value: matrix,
                color: color,
                onChanged: (m) => setSheet(() => matrix = m),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Lưu',
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await ref
                      .read(myProfileProvider.notifier)
                      .updateSkillMatrix(stats.sport, matrix);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
