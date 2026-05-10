import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/app_state.dart';
import 'features/screens/assistant_screen.dart';
import 'features/screens/auth_screen.dart';
import 'features/screens/category_screen.dart';
import 'features/screens/home_screen.dart';
import 'features/screens/notifications_screen.dart';
import 'features/screens/onboarding_screen.dart';
import 'features/screens/product_detail_screen.dart';
import 'features/screens/profile_screen.dart';
import 'features/screens/reminders_screen.dart';
import 'features/screens/routine_history_screen.dart';
import 'features/screens/routine_period_screen.dart';
import 'features/screens/routine_screen.dart';
import 'features/screens/scanner_screen.dart';
import 'features/screens/skin_profile_screen.dart';

class RoutineApp extends StatefulWidget {
  const RoutineApp({super.key});

  @override
  State<RoutineApp> createState() => _RoutineAppState();
}

class _RoutineAppState extends State<RoutineApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: state,
      redirect: (context, goState) {
        final unauth = state.authStatus == AuthStatus.signedOut ||
            state.authStatus == AuthStatus.unknown;
        final atAuth = goState.matchedLocation == '/auth';
        final atOnboarding = goState.matchedLocation == '/onboarding';
        if (unauth) return atAuth ? null : '/auth';
        if (!unauth && atAuth) return '/';
        // Only push first-run users through onboarding once we've actually
        // pulled their profile from Supabase (`profileFetched`) — otherwise
        // an existing user briefly looks "not onboarded" right after sign-in.
        if (state.isSignedIn &&
            !state.loading &&
            state.profileFetched &&
            !state.hasOnboarded) {
          return atOnboarding ? null : '/onboarding';
        }
        if (atOnboarding && state.hasOnboarded) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/history/:date',
          builder: (context, state) => RoutineHistoryScreen(
            date: state.pathParameters['date'] ?? '',
          ),
        ),
        GoRoute(
          path: '/category/:cat',
          builder: (context, state) =>
              CategoryScreen(category: state.pathParameters['cat'] ?? 'skin'),
        ),
        GoRoute(
          path: '/routine/:period',
          builder: (context, state) {
            final raw = (state.pathParameters['period'] ?? 'AM').toUpperCase();
            final period = raw == 'PM' ? 'PM' : 'AM';
            return RoutinePeriodScreen(period: period);
          },
        ),
        GoRoute(
          path: '/reminders',
          builder: (context, state) => const RemindersScreen(),
        ),
        GoRoute(
          path: '/product/:id',
          builder: (context, state) =>
              ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/settings/skin',
          builder: (context, state) => const SkinProfileScreen(),
        ),
        GoRoute(
          path: '/settings/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/routine', builder: (context, state) => const RoutineScreen()),
            GoRoute(path: '/scan', builder: (context, state) => const ScannerScreen()),
            GoRoute(path: '/chat', builder: (context, state) => const AssistantScreen()),
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Routine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _paths = ['/', '/routine', '/scan', '/chat', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    var index = _paths.indexOf(location);
    if (index < 0) index = 0;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_paths.length, (i) {
                    final selected = i == index;
                    final iconData = _iconFor(i);
                    final label = _labelFor(i);
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go(_paths[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.charcoal : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                iconData,
                                size: 20,
                                color: selected ? Colors.white : AppTheme.charcoal,
                              ),
                              if (selected) ...[
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(int index) {
    switch (index) {
      case 0:
        return Icons.home_outlined;
      case 1:
        return Icons.checklist_rtl_outlined;
      case 2:
        return Icons.center_focus_strong_outlined;
      case 3:
        return Icons.auto_awesome_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _labelFor(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Routine';
      case 2:
        return 'Scan';
      case 3:
        return 'Chat';
      default:
        return 'Profile';
    }
  }
}
