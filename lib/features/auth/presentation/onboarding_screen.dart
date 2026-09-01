import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/da_nang.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/playful_background.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/application/profile_provider.dart';
import '../../profile/presentation/skill_rating_editor.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();

  int _page = 0;
  String? _district;
  final Set<SportType> _sports = {};
  final Map<SportType, SkillMatrix> _ratings = {};
  bool _submitting = false;

  static const _lastPage = 2;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canNext {
    switch (_page) {
      case 0:
        return _nameCtrl.text.trim().length >= 2;
      case 1:
        return _district != null && _sports.isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_page < _lastPage) {
      // Đảm bảo mỗi môn có 1 SkillMatrix (mặc định 5).
      for (final s in _sports) {
        _ratings.putIfAbsent(s, () => const SkillMatrix.filled(5));
      }
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final sports = _sports.toList()..sort((a, b) => a.index.compareTo(b.index));
      await ref.read(myProfileProvider.notifier).completeOnboarding(
            fullName: _nameCtrl.text,
            district: _district!,
            sports: sports,
            ratings: {
              for (final s in sports)
                s: _ratings[s] ?? const SkillMatrix.filled(5),
            },
          );
      // Router tự chuyển sang '/' khi myProfileProvider hết needsOnboarding.
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Lưu chưa được, bạn thử lại chút nha!'),
          ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlayfulBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _ProgressDots(count: _lastPage + 1, active: _page),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (p) => setState(() => _page = p),
                  children: [
                    _NameStep(
                      controller: _nameCtrl,
                      onChanged: () => setState(() {}),
                    ),
                    _DistrictSportStep(
                      district: _district,
                      sports: _sports,
                      onDistrict: (d) => setState(() => _district = d),
                      onToggleSport: (s) => setState(() {
                        _sports.contains(s) ? _sports.remove(s) : _sports.add(s);
                      }),
                    ),
                    _RatingStep(
                      sports: _sports.toList()
                        ..sort((a, b) => a.index.compareTo(b.index)),
                      ratings: _ratings,
                      onChanged: (s, m) => setState(() => _ratings[s] = m),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    if (_page > 0) ...[
                      Expanded(
                        child: TextButton(
                          onPressed: _submitting ? null : _back,
                          child: const Text(
                            'Quay lại',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: _page < _lastPage ? 'Tiếp tục' : 'Vô sân thôi!',
                        icon: _page < _lastPage
                            ? Icons.arrow_forward_rounded
                            : Icons.sports_tennis,
                        loading: _submitting,
                        onPressed: _canNext ? _next : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: i == active ? 1 : 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Chào bạn! 👋',
      subtitle: 'Gọi bạn là gì cho thân thiện nè?',
      child: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        onChanged: (_) => onChanged(),
        decoration: const InputDecoration(
          hintText: 'Tên hoặc biệt danh',
          prefixIcon: Icon(Icons.emoji_emotions_outlined),
        ),
      ),
    );
  }
}

class _DistrictSportStep extends StatelessWidget {
  const _DistrictSportStep({
    required this.district,
    required this.sports,
    required this.onDistrict,
    required this.onToggleSport,
  });

  final String? district;
  final Set<SportType> sports;
  final ValueChanged<String> onDistrict;
  final ValueChanged<SportType> onToggleSport;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Bạn ở đâu, chơi gì?',
      subtitle: 'Để tụi mình gợi ý kèo gần bạn.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Quận / huyện ở Đà Nẵng',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in kDaNangDistricts)
                ChoiceChip(
                  label: Text(d),
                  selected: district == d,
                  onSelected: (_) => onDistrict(d),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Bạn quẩy môn nào? (chọn 1 hoặc cả hai)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final s in SportType.values) ...[
                Expanded(
                  child: _SportPick(
                    sport: s,
                    selected: sports.contains(s),
                    onTap: () => onToggleSport(s),
                  ),
                ),
                if (s != SportType.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SportPick extends StatelessWidget {
  const _SportPick({
    required this.sport,
    required this.selected,
    required this.onTap,
  });
  final SportType sport;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.sportColor(sport.dbValue);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              sport == SportType.tennis
                  ? Icons.sports_tennis
                  : Icons.sports_handball,
              color: selected ? color : Colors.black38,
              size: 30,
            ),
            const SizedBox(height: 6),
            Text(sport.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? color : Colors.black54,
                )),
          ],
        ),
      ),
    );
  }
}

class _RatingStep extends StatelessWidget {
  const _RatingStep({
    required this.sports,
    required this.ratings,
    required this.onChanged,
  });

  final List<SportType> sports;
  final Map<SportType, SkillMatrix> ratings;
  final void Function(SportType, SkillMatrix) onChanged;

  @override
  Widget build(BuildContext context) {
    if (sports.isEmpty) {
      return const _StepScaffold(
        title: 'Tự chấm điểm trình',
        child: Text('Quay lại bước trước chọn môn đã nha!'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tự chấm điểm trình',
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text('Kéo cho đúng cảm giác của bạn — chỉnh lại sau lúc nào cũng được.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 16),
          for (final sport in sports) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        sport == SportType.tennis
                            ? Icons.sports_tennis
                            : Icons.sports_handball,
                        color: AppTheme.sportColor(sport.dbValue),
                      ),
                      const SizedBox(width: 8),
                      Text(sport.label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SkillRatingEditor(
                    value: ratings[sport] ?? const SkillMatrix.filled(5),
                    color: AppTheme.sportColor(sport.dbValue),
                    onChanged: (m) => onChanged(sport, m),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
