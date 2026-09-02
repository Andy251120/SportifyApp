import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/bouncing_ball.dart';
import '../../../core/widgets/playful_background.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final onOtpStep = state.step == LoginStep.enterOtp;

    ref.listen(loginControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      body: PlayfulBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BouncingBalls(ballSize: 78),
                      const SizedBox(height: 6),
                      const _Wordmark(),
                      const SizedBox(height: 2),
                      const _Tagline('Vào sân chơi thôi!'),
                      const SizedBox(height: 22),
                      _EntranceAnimator(
                        child: _FormCard(
                          child: onOtpStep
                              ? _OtpForm(
                                  controller: _otpCtrl,
                                  phone: state.phoneE164,
                                  submitting: state.submitting,
                                  onConfirm: () {
                                    FocusScope.of(context).unfocus();
                                    controller.verifyOtp(_otpCtrl.text);
                                  },
                                  onChangePhone: () {
                                    _otpCtrl.clear();
                                    controller.backToPhone();
                                  },
                                )
                              : _PhoneForm(
                                  controller: _phoneCtrl,
                                  submitting: state.submitting,
                                  onSend: () {
                                    FocusScope.of(context).unfocus();
                                    controller.sendOtp(_phoneCtrl.text);
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Miễn phí · Cộng đồng Tennis & Pickleball Đà Nẵng',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Text(
        'Rally',
        style: GoogleFonts.fredoka(
          fontSize: 54,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.0,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tagline nhún nhảy nhẹ liên tục như quả bóng.
class _Tagline extends StatefulWidget {
  const _Tagline(this.text);
  final String text;

  @override
  State<_Tagline> createState() => _TaglineState();
}

class _TaglineState extends State<_Tagline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -3 * curved.value),
        child: Transform.rotate(angle: -0.02 + 0.04 * curved.value, child: child),
      ),
      child: Text(
        widget.text,
        style: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.96),
        ),
      ),
    );
  }
}

class _EntranceAnimator extends StatelessWidget {
  const _EntranceAnimator({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PhoneForm extends StatelessWidget {
  const _PhoneForm({
    required this.controller,
    required this.submitting,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            LengthLimitingTextInputFormatter(15),
          ],
          decoration: const InputDecoration(
            hintText: 'Số điện thoại để vô chơi nè',
            hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Nhận mã OTP',
          loading: submitting,
          onPressed: onSend,
        ),
        const SizedBox(height: 10),
        const Text(
          'Chưa có tài khoản? Đăng nhập lần đầu sẽ tự tạo hồ sơ cho bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
      ],
    );
  }
}

class _OtpForm extends StatelessWidget {
  const _OtpForm({
    required this.controller,
    required this.phone,
    required this.submitting,
    required this.onConfirm,
    required this.onChangePhone,
  });

  final TextEditingController controller;
  final String phone;
  final bool submitting;
  final VoidCallback onConfirm;
  final VoidCallback onChangePhone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nhập mã 6 số vừa gửi tới $phone',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(hintText: '••••••'),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Xác nhận & vào sân',
          icon: Icons.sports_tennis,
          loading: submitting,
          onPressed: onConfirm,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: submitting ? null : onChangePhone,
          child: const Text('Đổi số điện thoại khác'),
        ),
      ],
    );
  }
}
