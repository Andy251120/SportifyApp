import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/matches/presentation/confirm_result_screen.dart';
import '../../features/matches/presentation/report_result_screen.dart';
import '../../features/profile/application/profile_provider.dart';
import '../navigation/home_shell.dart';
import '../supabase/supabase_client.dart';

/// Router chính của app. Các Phase sau mở rộng thêm route cho từng feature.
final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);

  final refresh = ValueNotifier<int>(0);
  final authSub =
      client.auth.onAuthStateChange.listen((_) => refresh.value++);
  // Redirect chạy lại khi hồ sơ load xong / onboarding hoàn tất.
  ref.listen(myProfileProvider, (_, __) => refresh.value++);
  ref.onDispose(() {
    authSub.cancel();
    refresh.dispose();
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = client.auth.currentSession != null;
      final loc = state.matchedLocation;
      final onLogin = loc == '/login';
      final onOnboarding = loc == '/onboarding';

      if (!loggedIn) return onLogin ? null : '/login';

      final profile = ref.read(myProfileProvider);
      // Hồ sơ đang tải — ở nguyên, HomeShell hiện splash.
      if (profile.isLoading && !profile.hasValue) return onLogin ? '/' : null;

      final needsOnboarding = profile.valueOrNull?.needsOnboarding ?? true;
      if (needsOnboarding) return onOnboarding ? null : '/onboarding';

      if (onLogin || onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/matches/report',
        builder: (context, state) => const ReportResultScreen(),
      ),
      GoRoute(
        path: '/matches/confirm',
        builder: (context, state) => const ConfirmResultScreen(),
      ),
    ],
  );
});
