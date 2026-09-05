import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/profile/application/profile_provider.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/friendly_empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/splash_screen.dart';

/// Khung chính sau đăng nhập: 5 chỗ ở thanh dưới —
/// Trang chủ · Ghép kèo · (nút giữa nổi bật) · Sân · Hồ sơ.
/// Phase 0: mỗi tab chỉ là placeholder ghi tên tab.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = <_TabInfo>[
    _TabInfo('Trang chủ', Icons.home_rounded, '🏠', 'Feed cộng đồng sẽ xuất hiện ở đây'),
    _TabInfo('Ghép kèo', Icons.people_alt_rounded, '🤝', 'Chỗ để rủ nhau ra sân đánh vài séc'),
    _TabInfo('Sân', Icons.place_rounded, '📍', 'Bản đồ các sân tennis / pickleball ở Đà Nẵng'),
    _TabInfo('Hồ sơ', Icons.person_rounded, '🙂', 'Điểm trình, radar Show-off, thành tích của bạn'),
  ];

  void _openCenterAction() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('🎾', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Tạo nhanh kèo & nhập kết quả',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Ghi kết quả trận đấu',
              icon: Icons.sports_score,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/matches/report');
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/matches/confirm');
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Trận đấu của tôi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu() {
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final sport = ref.watch(viewedSportProvider);
    final stats = profile?.statsFor(sport);

    return PopupMenuButton<String>(
      onSelected: (v) {
        switch (v) {
          case 'basics':
            showEditBasicsSheet(context, ref);
          case 'skill':
            if (stats != null) {
              showEditSkillSheet(context, ref, sport, stats.skillMatrix);
            }
          case 'signout':
            ref.read(authRepositoryProvider).signOut();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'basics', child: Text('Sửa tên / khu vực')),
        if (stats != null)
          PopupMenuItem(
              value: 'skill',
              child: Text('Sửa điểm trình ${sport.label}')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'signout', child: Text('Đăng xuất')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];

    // Chờ hồ sơ tải xong trước khi hiện shell (router đã lo phần onboarding).
    final profileAsync = ref.watch(myProfileProvider);
    if (profileAsync.isLoading && !profileAsync.hasValue) {
      return const SplashScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tab.label),
        centerTitle: true,
        actions: _index == 3 ? [_buildProfileMenu()] : null,
      ),
      body: _index == 3
          ? const ProfileScreen()
          : FriendlyEmptyState(emoji: tab.emoji, title: tab.label, message: tab.blurb),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _openCenterAction,
        backgroundColor: AppTheme.tennisBallOrange,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 34),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(info: _tabs[0], selected: _index == 0, onTap: () => setState(() => _index = 0)),
            _NavItem(info: _tabs[1], selected: _index == 1, onTap: () => setState(() => _index = 1)),
            const SizedBox(width: 48),
            _NavItem(info: _tabs[2], selected: _index == 2, onTap: () => setState(() => _index = 2)),
            _NavItem(info: _tabs[3], selected: _index == 3, onTap: () => setState(() => _index = 3)),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo(this.label, this.icon, this.emoji, this.blurb);
  final String label;
  final IconData icon;
  final String emoji;
  final String blurb;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.info, required this.selected, required this.onTap});

  final _TabInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.courtGreen : Colors.black45;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, color: color),
          const SizedBox(height: 2),
          Text(
            info.label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

