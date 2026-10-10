import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/workout_plan.dart';
import '../../services/firestore_service.dart';
import 'log_workout_screen.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String planId;

  const WorkoutDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(firestoreServiceProvider).getWorkoutPlan(planId);

    return FutureBuilder<WorkoutPlan?>(
      future: planAsync,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout')),
            body: Center(child: Text('Error: ${snapshot.error ?? 'Plan not found'}')),
          );
        }

        final plan = snapshot.data!;
        return _WorkoutDetailView(plan: plan);
      },
    );
  }
}

class _WorkoutDetailView extends ConsumerWidget {
  final WorkoutPlan plan;

  const _WorkoutDetailView({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => context.push('/member/log-workout?planId=${plan.id}'),
            tooltip: 'Start Workout',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plan.exercises.length,
        itemBuilder: (context, index) {
          final ex = plan.exercises[index];
          return _ExerciseDetailCard(exercise: ex, index: index);
        },
      ),
      bottomNavigationBar: plan.status == WorkoutPlanStatus.active
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: FilledButton(
                onPressed: () => context.push('/member/log-workout?planId=${plan.id}'),
                child: const Text('Start Workout'),
              ),
            )
          : null,
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;

  const _ExerciseDetailCard({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _DetailChip(
                  label: '${exercise.sets} sets',
                  icon: Icons.repeat,
                ),
                _DetailChip(
                  label: exercise.durationSeconds != null
                      ? '${exercise.durationSeconds!} sec'
                      : '${exercise.reps} reps',
                  icon: Icons.timer,
                ),
                if (exercise.weight != null)
                  _DetailChip(
                    label: '${exercise.weight} kg',
                    icon: Icons.fitness_center,
                  ),
                _DetailChip(
                  label: '${exercise.restSeconds} sec rest',
                  icon: Icons.pause,
                ),
              ],
            ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise.notes!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DetailChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}