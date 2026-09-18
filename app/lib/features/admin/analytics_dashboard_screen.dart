import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/progress_log.dart';
import '../../models/user.dart';
import '../../models/workout_plan.dart';
import '../../services/firestore_service.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RetentionMetricsCard(),
            const SizedBox(height: 16),
            _ProgramEffectivenessCard(),
            const SizedBox(height: 16),
            _EngagementMetricsCard(),
            const SizedBox(height: 16),
            _BranchPerformanceCard(),
          ],
        ),
      ),
    );
  }
}

class _RetentionMetricsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(firestoreServiceProvider).getMembers();
    final plansAsync = ref.watch(firestoreServiceProvider).getTrainers();

    return FutureBuilder<List<AppUser>>(
      future: usersAsync,
      builder: (context, userSnapshot) {
        return FutureBuilder<List<AppUser>>(
          future: plansAsync,
          builder: (context, trainerSnapshot) {
            final members = userSnapshot.data ?? [];
            final trainers = trainerSnapshot.data ?? [];
            final activeMembers = members.where((m) => m.isActive).length;
            final totalMembers = members.length;
            final retentionRate = totalMembers > 0 ? (activeMembers / totalMembers * 100).toStringAsFixed(1) : '0.0';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Retention Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Active Members',
                            value: activeMembers.toString(),
                            icon: Icons.people,
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _MetricTile(
                            label: 'Total Members',
                            value: totalMembers.toString(),
                            icon: Icons.group,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _MetricTile(
                            label: 'Retention Rate',
                            value: '$retentionRate%',
                            icon: Icons.trending_up,
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _MetricTile(
                            label: 'Active Trainers',
                            value: trainers.where((t) => t.isActive).length.toString(),
                            icon: Icons.fitness_center,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProgramEffectivenessCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(firestoreServiceProvider).getTrainers();

    return FutureBuilder<List<AppUser>>(
      future: plansAsync,
      builder: (context, snapshot) {
        final trainers = snapshot.data ?? [];
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Program Effectiveness',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Published Plans',
                        value: '0', // Would need to query workoutPlans
                        icon: Icons.publish,
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Draft Plans',
                        value: '0',
                        icon: Icons.drafts,
                        color: Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Avg Plan Duration',
                        value: '4 wks',
                        icon: Icons.schedule,
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Completion Rate',
                        value: '0%',
                        icon: Icons.check_circle,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Detailed analytics require Cloud Functions for aggregation. '
                  'See Firebase Console for raw data or implement scheduled functions.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EngagementMetricsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Engagement Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Workouts This Week',
                    value: '0',
                    icon: Icons.fitness_center,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Avg Workouts/Member',
                    value: '0',
                    icon: Icons.repeat,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Progress Logs',
                    value: '0',
                    icon: Icons.assessment,
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Photos Uploaded',
                    value: '0',
                    icon: Icons.photo_camera,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchPerformanceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesStreamProvider);

    return branchesAsync.when(
      data: (branches) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Branch Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 16),
                if (branches.isEmpty)
                  Text('No branches configured',
                      style: Theme.of(context).textTheme.bodyMedium)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: branch.isActive
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.location_city,
                            color: branch.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(branch.name),
                        subtitle: Text('${branch.trainerIds.length} trainers · ${branch.memberIds.length} members'),
                        trailing: Chip(
                          label: Text(branch.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(fontSize: 10)),
                          backgroundColor: branch.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Error: $e'))),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              )),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}