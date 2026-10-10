import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../models/workout_plan.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../shared/exercise_picker.dart';

class CreateWorkoutPlanScreen extends ConsumerStatefulWidget {
  final WorkoutPlan? existingPlan;

  const CreateWorkoutPlanScreen({super.key, this.existingPlan});

  @override
  ConsumerState<CreateWorkoutPlanScreen> createState() => _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends ConsumerState<CreateWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationWeeksController = TextEditingController(text: '4');
  
  List<WorkoutExercise> _exercises = [];
  bool _isLoading = false;
  WorkoutPlanStatus _status = WorkoutPlanStatus.draft;

  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _nameController.text = widget.existingPlan!.name;
      _descriptionController.text = widget.existingPlan!.description ?? '';
      _durationWeeksController.text = widget.existingPlan!.durationWeeks.toString();
      _exercises = List.from(widget.existingPlan!.exercises);
      _status = widget.existingPlan!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationWeeksController.dispose();
    super.dispose();
  }

  void _addExercise() async {
    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ExercisePickerBottomSheet(),
    );
    
    if (exercise != null && mounted) {
      setState(() {
        _exercises.add(WorkoutExercise(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          sets: exercise.defaultSets ?? 3,
          reps: exercise.defaultReps ?? 10,
          durationSeconds: exercise.defaultDurationSeconds,
          weight: exercise.defaultWeight,
          order: _exercises.length,
        ));
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      // Reorder
      for (int i = 0; i < _exercises.length; i++) {
        _exercises[i] = _exercises[i].copyWith(order: i);
      }
    });
  }

  void _updateExercise(int index, WorkoutExercise updated) {
    setState(() {
      _exercises[index] = updated;
    });
  }

  Future<void> _savePlan({bool publish = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentAppUserProvider).value;
      if (user == null) throw Exception('Not authenticated');

      final plan = WorkoutPlan(
        id: widget.existingPlan?.id ?? '',
        trainerId: user.uid,
        trainerName: user.displayName,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        exercises: _exercises,
        status: publish ? WorkoutPlanStatus.active : _status,
        assignedMemberIds: widget.existingPlan?.assignedMemberIds ?? [],
        createdAt: widget.existingPlan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        durationWeeks: int.tryParse(_durationWeeksController.text) ?? 4,
      );

      if (widget.existingPlan != null) {
        await ref.read(firestoreServiceProvider).updateWorkoutPlan(plan);
      } else {
        await ref.read(firestoreServiceProvider).createWorkoutPlan(plan);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(publish ? 'Plan published!' : 'Plan saved as draft')),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPlan != null ? 'Edit Workout Plan' : 'Create Workout Plan'),
        actions: [
          if (widget.existingPlan != null)
            TextButton.icon(
              onPressed: () => _savePlan(publish: true),
              icon: const Icon(Icons.publish),
              label: const Text('Publish'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name *',
                        hintText: 'e.g., 4-Week Strength Builder',
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional description for members',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _durationWeeksController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (weeks)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 1 ? 'Enter valid weeks' : null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exercises (${_exercises.length})',
                            style: Theme.of(context).textTheme.titleLarge),
                        FilledButton.icon(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exercise'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_exercises.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.fitness_center,
                                  size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text('No exercises added yet',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Tap "Add Exercise" to build your workout plan',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  )),
                            ],
                          ),
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) newIndex--;
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                            for (int i = 0; i < _exercises.length; i++) {
                              _exercises[i] = _exercises[i].copyWith(order: i);
                            }
                          });
                        },
                        itemBuilder: (context, index) {
                          final ex = _exercises[index];
                          return _ExerciseCard(
                            key: ValueKey(ex.exerciseId + index.toString()),
                            exercise: ex,
                            index: index,
                            onUpdate: (updated) => _updateExercise(index, updated),
                            onDelete: () => _removeExercise(index),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : () => _savePlan(),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.existingPlan != null ? 'Save Changes' : 'Save Draft'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final Function(WorkoutExercise) onUpdate;
  final VoidCallback onDelete;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(exercise.exerciseId),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
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
                IconButton(
                  icon: const Icon(Icons.drag_indicator),
                  onPressed: null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: exercise.sets.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onUpdate(exercise.copyWith(sets: int.tryParse(v) ?? exercise.sets)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: exercise.reps.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onUpdate(exercise.copyWith(reps: int.tryParse(v) ?? exercise.reps)),
                  ),
                ),
                const SizedBox(width: 12),
                if (exercise.durationSeconds != null) ...[
                  Expanded(
                    child: TextFormField(
                      initialValue: exercise.durationSeconds.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Duration (sec)',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => onUpdate(exercise.copyWith(durationSeconds: int.tryParse(v))),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (exercise.weight != null) ...[
                  Expanded(
                    child: TextFormField(
                      initialValue: exercise.weight.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => onUpdate(exercise.copyWith(weight: double.tryParse(v))),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextFormField(
                    initialValue: exercise.restSeconds.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Rest (sec)',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onUpdate(exercise.copyWith(restSeconds: int.tryParse(v) ?? exercise.restSeconds)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: exercise.notes,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Form cues, modifications, etc.',
                isDense: true,
              ),
              onChanged: (v) => onUpdate(exercise.copyWith(notes: v.isEmpty ? null : v)),
            ),
          ],
        ),
      ),
    );
  }
}