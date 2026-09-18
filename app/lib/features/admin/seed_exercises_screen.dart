import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firestore_service.dart';

class SeedExercisesScreen extends ConsumerWidget {
  const SeedExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Exercise Library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercise Library Seeder',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'This will populate Firestore with a comprehensive exercise library '
                      'organized by type (Strength, Cardio, HIIT, Yoga, etc.). '
                      'Safe to run multiple times - duplicates are prevented by checking existing names.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _seedExercises(context, ref),
                      icon: const Icon(Icons.download),
                      label: const Text('Seed Exercises'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Default Exercises Included',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 12),
                    ..._exerciseCategories.map((category) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(category.category),
                        children: category.exercises.map((ex) => ListTile(
                          dense: true,
                          title: Text(ex),
                          leading: Icon(_getTypeIcon(category.category)),
                        )).toList(),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedExercises(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(firestoreServiceProvider).seedExercises();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Exercise library seeded successfully!')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  IconData _getTypeIcon(String category) {
    return switch (category.toLowerCase()) {
      'strength' => Icons.fitness_center,
      'cardio' => Icons.directions_run,
      'hiit' => Icons.flash_on,
      'yoga' => Icons.spa,
      'pilates' => Icons.accessibility,
      'flexibility' => Icons.self_improvement,
      _ => Icons.fitness_center,
    };
  }
}

class _ExerciseCategory {
  final String category;
  final List<String> exercises;

  const _ExerciseCategory(this.category, this.exercises);
}

final _exerciseCategories = [
  _ExerciseCategory('Strength', [
    'Push-ups', 'Pull-ups', 'Squats', 'Deadlifts', 'Bench Press',
    'Overhead Press', 'Barbell Rows', 'Lunges', 'Romanian Deadlifts',
    'Dips', 'Chin-ups', 'Hip Thrusts', 'Bulgarian Split Squats',
    'Face Pulls', 'Plank', 'Side Plank', 'Russian Twists',
    'Leg Press', 'Leg Curls', 'Calf Raises',
  ]),
  _ExerciseCategory('Cardio', [
    'Running', 'Cycling', 'Rowing', 'Swimming', 'Jump Rope',
    'Elliptical', 'Stair Climber', 'Walking', 'Hiking',
    'Battle Ropes', 'Sled Push', 'Farmer\'s Walk',
  ]),
  _ExerciseCategory('HIIT', [
    'Burpees', 'Mountain Climbers', 'High Knees', 'Jump Squats',
    'Box Jumps', 'Kettlebell Swings', 'Sprints', 'Bear Crawls',
    'Plank Jacks', 'Tuck Jumps',
  ]),
  _ExerciseCategory('Yoga', [
    'Sun Salutation A', 'Sun Salutation B', 'Warrior I', 'Warrior II',
    'Triangle Pose', 'Tree Pose', 'Downward Dog', 'Upward Dog',
    'Child\'s Pose', 'Pigeon Pose', 'Cobra Pose', 'Bridge Pose',
  ]),
  _ExerciseCategory('Pilates', [
    'The Hundred', 'Roll Up', 'Single Leg Circle', 'Rolling Like a Ball',
    'Single Leg Stretch', 'Double Leg Stretch', 'Spine Stretch Forward',
    'Saw', 'Swan Dive', 'Side Kick Series', 'Teaser',
  ]),
  _ExerciseCategory('Flexibility', [
    'Hamstring Stretch', 'Quad Stretch', 'Hip Flexor Stretch',
    'Chest Opener', 'Shoulder Stretch', 'Tricep Stretch',
    'Cat-Cow', 'Thread the Needle', 'Figure 4 Stretch',
    'Foam Rolling - Back', 'Foam Rolling - Legs',
  ]),
];