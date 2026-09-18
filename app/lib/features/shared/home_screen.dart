import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../models/workout_plan.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../trainer/trainer_dashboard.dart';
import 'member_dashboard.dart';
import 'workout_detail_screen.dart';
import 'log_workout_screen.dart';
import '../admin/admin_dashboard.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return switch (user.role) {
          UserRole.trainer => const TrainerDashboard(),
          UserRole.member => const MemberDashboard(),
          UserRole.admin => const AdminDashboard(),
        };
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(currentAppUserProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}