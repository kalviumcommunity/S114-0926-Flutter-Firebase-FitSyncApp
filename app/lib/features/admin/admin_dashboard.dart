import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/branch.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _BranchesTab(),
      _TrainersTab(),
      _AnalyticsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
          NavigationDestination(icon: Icon(Icons.location_city), label: 'Branches'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Trainers'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
        ],
      ),
    );
  }
}

class _BranchesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesStreamProvider);

    return branchesAsync.when(
      data: (branches) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Branches (${branches.length})',
                      style: Theme.of(context).textTheme.titleLarge),
                  FilledButton.icon(
                    onPressed: () => context.push('/admin/branches/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Branch'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: branches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_city, size: 80, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          Text('No branches yet',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text('Add your first branch location',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: branches.length,
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        return _BranchCard(branch: branch);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _BranchCard extends ConsumerWidget {
  final Branch branch;

  const _BranchCard({required this.branch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      Text(branch.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                      Text(branch.address,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                Chip(
                  label: Text(branch.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: branch.isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                      color: branch.isActive ? Colors.green : Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _StatChip(label: '${branch.trainerIds.length} Trainers', icon: Icons.fitness_center),
                _StatChip(label: '${branch.memberIds.length} Members', icon: Icons.people),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context.push('/admin/branches/${branch.id}'),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _TrainersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesStreamProvider);

    return branchesAsync.when(
      data: (branches) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Trainer Management',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return _BranchTrainersCard(branch: branch);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _BranchTrainersCard extends ConsumerWidget {
  final Branch branch;

  const _BranchTrainersCard({required this.branch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, just show branch info with trainer count
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${branch.trainerIds.length} trainers · ${branch.memberIds.length} members'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trainer IDs:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (branch.trainerIds.isEmpty)
                  Text('No trainers assigned', style: Theme.of(context).textTheme.bodyMedium)
                else
                  Wrap(
                    spacing: 8,
                    children: branch.trainerIds.map((id) => Chip(label: Text(id))).toList(),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    // TODO: Navigate to trainer assignment
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign Trainer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Analytics Dashboard',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Retention metrics, program effectiveness, and more',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: Open detailed analytics
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('View Reports'),
          ),
        ],
      ),
    );
  }
}