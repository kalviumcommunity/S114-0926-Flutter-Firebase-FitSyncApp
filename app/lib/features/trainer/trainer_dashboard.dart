import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../models/workout_plan.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'create_workout_plan_screen.dart';
import 'member_progress_screen.dart';

class TrainerDashboard extends ConsumerStatefulWidget {
  const TrainerDashboard({super.key});

  @override
  ConsumerState<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends ConsumerState<TrainerDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).value;

    final screens = [
      _MyPlansTab(),
      _MyMembersTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authServiceProvider).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              )),
            ],
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'My Plans'),
          NavigationDestination(icon: Icon(Icons.people), label: 'My Members'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/trainer/create-plan'),
              icon: const Icon(Icons.add),
              label: const Text('Create Plan'),
            )
          : null,
    );
  }
}

class _MyPlansTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final plansAsync = ref.watch(trainerWorkoutPlansProvider(user.uid));

    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('No workout plans yet',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Create your first workout plan',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/trainer/create-plan'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Plan'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _PlanCard(plan: plan);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final WorkoutPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (plan.status) {
      WorkoutPlanStatus.draft => Colors.grey,
      WorkoutPlanStatus.active => Colors.green,
      WorkoutPlanStatus.archived => Colors.orange,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        '${plan.totalExercises} exercises · ~${plan.estimatedDurationMinutes} min · ${plan.durationWeeks} weeks',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(plan.status.name.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: statusColor.withOpacity(0.1),
                  side: BorderSide(color: statusColor),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            if (plan.description != null) ...[
              const SizedBox(height: 8),
              Text(plan.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${plan.assignedMemberIds.length} members assigned',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/trainer/create-plan', extra: plan),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                if (plan.status == WorkoutPlanStatus.draft)
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await ref.read(firestoreServiceProvider).updateWorkoutPlan(
                        plan.copyWith(status: WorkoutPlanStatus.active),
                      );
                    },
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text('Publish'),
                  )
                else if (plan.status == WorkoutPlanStatus.active)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(firestoreServiceProvider).updateWorkoutPlan(
                        plan.copyWith(status: WorkoutPlanStatus.archived),
                      );
                    },
                    icon: const Icon(Icons.archive, size: 18),
                    label: const Text('Archive'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyMembersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final membersAsync = ref.watch(firestoreServiceProvider).getMembers(trainerId: user.uid);

    return FutureBuilder<List<AppUser>>(
      future: membersAsync,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final members = snapshot.data ?? [];
        
        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('No members assigned',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Members will appear here when assigned',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return _MemberCard(member: member);
          },
        );
      },
    );
  }
}

class _MemberCard extends ConsumerWidget {
  final AppUser member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(member.email),
        trailing: FilledButton.tonal(
          onPressed: () => context.push('/trainer/member-progress', extra: member),
          child: const Text('View Progress'),
        ),
        onTap: () => context.push('/trainer/member-progress', extra: member),
      ),
    );
  }
}