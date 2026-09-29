import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/shared/home_screen.dart';
import 'features/trainer/create_workout_plan_screen.dart';
import 'features/trainer/member_progress_screen.dart';
import 'features/shared/workout_detail_screen.dart';
import 'features/shared/log_workout_screen.dart';
import 'features/shared/profile_screen.dart';
import 'features/admin/analytics_dashboard_screen.dart';
import 'features/admin/seed_exercises_screen.dart';
import 'features/admin/member_transfer_screen.dart';
import 'features/admin/branch_management_screen.dart';
import '../../models/user.dart';
import '../../models/workout_plan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Trainer routes
    GoRoute(
      path: '/trainer/create-plan',
      builder: (context, state) {
        final plan = state.extra as WorkoutPlan?;
        return CreateWorkoutPlanScreen(existingPlan: plan);
      },
    ),
    GoRoute(
      path: '/trainer/member-progress',
      builder: (context, state) {
        final member = state.extra as AppUser;
        return MemberProgressScreen(member: member);
      },
    ),
    // Member routes
    GoRoute(
      path: '/member/workout/:planId',
      builder: (context, state) {
        final planId = state.pathParameters['planId']!;
        return WorkoutDetailScreen(planId: planId);
      },
    ),
    GoRoute(
      path: '/member/log-workout',
      builder: (context, state) {
        final planId = state.uri.queryParameters['planId'];
        return LogWorkoutScreen(planId: planId);
      },
    ),
    // Admin routes
    GoRoute(
      path: '/admin/branches/new',
      builder: (context, state) => const BranchManagementScreen(),
    ),
    GoRoute(
      path: '/admin/branches/:branchId',
      builder: (context, state) {
        final branchId = state.pathParameters['branchId']!;
        return const BranchManagementScreen();
      },
    ),
    GoRoute(
      path: '/admin/analytics',
      builder: (context, state) => const AnalyticsDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/seed-exercises',
      builder: (context, state) => const SeedExercisesScreen(),
    ),
    GoRoute(
      path: '/admin/transfer-member',
      builder: (context, state) {
        final member = state.extra as AppUser;
        return MemberTransferScreen(member: member);
      },
    ),
    // Profile route
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
      ),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'FitTrack',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Fitness Journey Starts Here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.person_add),
              label: const Text('Create Account'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}