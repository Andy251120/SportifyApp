import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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

    ref.listen(loginControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🎾🏓', style: TextStyle(fontSize: 52), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Vào sân chơi thôi!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.courtGreen),
              ),
              const SizedBox(height: 8),
              Text(
                state.step == LoginStep.enterPhone
                    ? 'Nhập số điện thoại để nhận mã đăng nhập nhé'
                    : 'Bọn mình vừa gửi mã 6 số tới\n${state.phoneE164}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              if (state.step == LoginStep.enterPhone)
                _PhoneField(controller: _phoneCtrl)
              else
                _OtpField(controller: _otpCtrl),
              const SizedBox(height: 24),
              if (state.step == LoginStep.enterPhone)
                PrimaryButton(
                  label: 'Gửi mã cho tôi',
                  icon: Icons.sms_outlined,
                  loading: state.submitting,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    controller.sendOtp(_phoneCtrl.text);
                  },
                )
              else ...[
                PrimaryButton(
                  label: 'Xác nhận & vào sân',
                  icon: Icons.sports_tennis,
                  loading: state.submitting,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    controller.verifyOtp(_otpCtrl.text);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: state.submitting
                      ? null
                      : () {
                          _otpCtrl.clear();
                          controller.backToPhone();
                        },
                  child: const Text('Đổi số điện thoại khác'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      autofocus: true,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
        LengthLimitingTextInputFormatter(15),
      ],
      decoration: const InputDecoration(
        hintText: '09xx xxx xxx',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  const _OtpField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      autofocus: true,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: const InputDecoration(hintText: '••••••'),
    );
  }
}
