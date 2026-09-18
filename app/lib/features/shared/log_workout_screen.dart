import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/progress_log.dart';
import '../../models/workout_plan.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class LogWorkoutScreen extends ConsumerStatefulWidget {
  final String? planId;

  const LogWorkoutScreen({super.key, this.planId});

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  WorkoutPlan? _plan;
  final Map<String, List<CompletedSet>> _completedSets = {};
  final Map<String, String> _exerciseNotes = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.planId != null) {
      _loadPlan();
    }
  }

  Future<void> _loadPlan() async {
    try {
      final plan = await ref.read(firestoreServiceProvider).getWorkoutPlan(widget.planId!);
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
          // Initialize completed sets
          for (final ex in plan!.exercises) {
            _completedSets[ex.exerciseId] = List.generate(
              ex.sets,
              (index) => CompletedSet(
                setNumber: index + 1,
                completed: false,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plan: $e')),
        );
      }
    }
  }

  void _toggleSet(String exerciseId, int setIndex) {
    final sets = _completedSets[exerciseId] ?? [];
    if (setIndex < sets.length) {
      setState(() {
        final updatedSets = List<CompletedSet>.from(sets);
        final current = updatedSets[setIndex];
        updatedSets[setIndex] = current.copyWith(
          completed: !current.completed,
        );
        _completedSets[exerciseId] = updatedSets;
      });
    }
  }

  void _updateSetReps(String exerciseId, int setIndex, int? reps) {
    final sets = _completedSets[exerciseId] ?? [];
    if (setIndex < sets.length) {
      setState(() {
        final updatedSets = List<CompletedSet>.from(sets);
        final current = updatedSets[setIndex];
        updatedSets[setIndex] = current.copyWith(reps: reps);
        _completedSets[exerciseId] = updatedSets;
      });
    }
  }

  void _updateSetWeight(String exerciseId, int setIndex, double? weight) {
    final sets = _completedSets[exerciseId] ?? [];
    if (setIndex < sets.length) {
      setState(() {
        final updatedSets = List<CompletedSet>.from(sets);
        final current = updatedSets[setIndex];
        updatedSets[setIndex] = current.copyWith(weight: weight);
        _completedSets[exerciseId] = updatedSets;
      });
    }
  }

  void _updateSetDuration(String exerciseId, int setIndex, int? duration) {
    final sets = _completedSets[exerciseId] ?? [];
    if (setIndex < sets.length) {
      setState(() {
        final updatedSets = List<CompletedSet>.from(sets);
        final current = updatedSets[setIndex];
        updatedSets[setIndex] = current.copyWith(durationSeconds: duration);
        _completedSets[exerciseId] = updatedSets;
      });
    }
  }

  Future<void> _submitWorkout() async {
    if (_plan == null) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentAppUserProvider).value;
      if (user == null) throw Exception('Not authenticated');

      final completedExercises = <CompletedExercise>[];
      
      for (final ex in _plan!.exercises) {
        final sets = _completedSets[ex.exerciseId] ?? [];
        final completedSets = sets.where((s) => s.completed).toList();
        
        if (completedSets.isNotEmpty) {
          completedExercises.add(CompletedExercise(
            exerciseId: ex.exerciseId,
            exerciseName: ex.exerciseName,
            sets: completedSets,
            notes: _exerciseNotes[ex.exerciseId],
          ));
        }
      }

      if (completedExercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete at least one set')),
        );
        return;
      }

      // Calculate duration and calories (rough estimate)
      int totalMinutes = 0;
      for (final ex in completedExercises) {
        for (final set in ex.sets) {
          totalMinutes += set.durationSeconds ?? (set.reps ?? 0) * 5;
        }
      }
      totalMinutes = (totalMinutes / 60).ceil();

      final log = ProgressLog(
        id: '',
        memberId: user.uid,
        memberName: user.displayName,
        trainerId: _plan!.trainerId,
        workoutPlanId: _plan!.id,
        type: LogType.workout,
        date: DateTime.now(),
        workoutName: _plan!.name,
        completedExercises: completedExercises,
        durationMinutes: totalMinutes,
        caloriesBurned: totalMinutes * 8.0, // rough estimate
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).createProgressLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout logged successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Log Workout')),
        body: const Center(child: Text('Plan not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Log: ${_plan!.name}'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plan!.exercises.length,
        itemBuilder: (context, index) {
          final ex = _plan!.exercises[index];
          final sets = _completedSets[ex.exerciseId] ?? [];
          return _ExerciseLogCard(
            exercise: ex,
            sets: sets,
            onToggleSet: (setIndex) => _toggleSet(ex.exerciseId, setIndex),
            onUpdateReps: (setIndex, reps) => _updateSetReps(ex.exerciseId, setIndex, reps),
            onUpdateWeight: (setIndex, weight) => _updateSetWeight(ex.exerciseId, setIndex, weight),
            onUpdateDuration: (setIndex, duration) => _updateSetDuration(ex.exerciseId, setIndex, duration),
            onNotesChanged: (notes) => setState(() => _exerciseNotes[ex.exerciseId] = notes),
            currentNotes: _exerciseNotes[ex.exerciseId],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: FilledButton(
          onPressed: _isSubmitting ? null : _submitWorkout,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Workout'),
        ),
      ),
    );
  }
}

class _ExerciseLogCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final List<CompletedSet> sets;
  final Function(int) onToggleSet;
  final Function(int, int?) onUpdateReps;
  final Function(int, double?) onUpdateWeight;
  final Function(int, int?) onUpdateDuration;
  final Function(String) onNotesChanged;
  final String? currentNotes;

  const _ExerciseLogCard({
    required this.exercise,
    required this.sets,
    required this.onToggleSet,
    required this.onUpdateReps,
    required this.onUpdateWeight,
    required this.onUpdateDuration,
    required this.onNotesChanged,
    this.currentNotes,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = sets.where((s) => s.completed).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    '${exercise.order + 1}',
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
                Chip(
                  label: Text('$completedCount/${sets.length} sets',
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: completedCount == sets.length
                      ? Colors.green.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                      color: completedCount == sets.length ? Colors.green : null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final set = entry.value;
              return _SetRow(
                set: set,
                setNumber: setIndex + 1,
                targetReps: exercise.reps,
                targetWeight: exercise.weight,
                targetDuration: exercise.durationSeconds,
                onToggle: () => onToggleSet(setIndex),
                onRepsChanged: (v) => onUpdateReps(setIndex, v),
                onWeightChanged: (v) => onUpdateWeight(setIndex, v),
                onDurationChanged: (v) => onUpdateDuration(setIndex, v),
              );
            }),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: currentNotes,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How did it feel? Form cues?',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
              onChanged: onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final CompletedSet set;
  final int setNumber;
  final int? targetReps;
  final double? targetWeight;
  final int? targetDuration;
  final VoidCallback onToggle;
  final Function(int?) onRepsChanged;
  final Function(double?) onWeightChanged;
  final Function(int?) onDurationChanged;

  const _SetRow({
    required this.set,
    required this.setNumber,
    this.targetReps,
    this.targetWeight,
    this.targetDuration,
    required this.onToggle,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: set.completed,
            onChanged: (_) => onToggle(),
          ),
          SizedBox(
            width: 40,
            child: Text(
              'Set $setNumber',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (targetReps != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: set.reps?.toString(),
                decoration: InputDecoration(
                  labelText: 'Reps',
                  hintText: targetReps.toString(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => onRepsChanged(int.tryParse(v)),
              ),
            ),
          ],
          if (targetWeight != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: set.weight?.toString(),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: targetWeight.toString(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => onWeightChanged(double.tryParse(v)),
              ),
            ),
          ],
          if (targetDuration != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: TextFormField(
                initialValue: set.durationSeconds?.toString(),
                decoration: InputDecoration(
                  labelText: 'Duration (sec)',
                  hintText: targetDuration.toString(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => onDurationChanged(int.tryParse(v)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension CompletedSetCopyWith on CompletedSet {
  CompletedSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? durationSeconds,
    bool? completed,
  }) {
    return CompletedSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
    );
  }
}