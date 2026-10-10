import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workout_plan.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';

class ExercisePickerBottomSheet extends ConsumerStatefulWidget {
  const ExercisePickerBottomSheet({super.key});

  @override
  ConsumerState<ExercisePickerBottomSheet> createState() => _ExercisePickerBottomSheetState();
}

class _ExercisePickerBottomSheetState extends ConsumerState<ExercisePickerBottomSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ExerciseType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Select Exercise',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search exercises',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedType == null,
                            onSelected: (_) => setState(() => _selectedType = null),
                          ),
                          ...ExerciseType.values.map((type) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              label: Text(type.name.toUpperCase()),
                              selected: _selectedType == type,
                              onSelected: (_) => setState(() => _selectedType = type),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: exercisesAsync.when(
                  data: (exercises) {
                    final filtered = exercises.where((ex) {
                      final matchesSearch = _searchQuery.isEmpty ||
                          ex.name.toLowerCase().contains(_searchQuery) ||
                          ex.muscleGroups.any((m) => m.toLowerCase().contains(_searchQuery));
                      final matchesType = _selectedType == null || ex.type == _selectedType;
                      return matchesSearch && matchesType;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text('No exercises found',
                            style: Theme.of(context).textTheme.bodyLarge),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ex = filtered[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getTypeColor(ex.type).withValues(alpha: 0.2),
                              child: Icon(_getTypeIcon(ex.type),
                                  color: _getTypeColor(ex.type)),
                            ),
                            title: Text(ex.name),
                            subtitle: Text(
                              '${ex.type.name.toUpperCase()} · ${ex.muscleGroups.join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: const Icon(Icons.add),
                            onTap: () => Navigator.pop(context, ex),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getTypeColor(ExerciseType type) {
    return switch (type) {
      ExerciseType.strength => Colors.red,
      ExerciseType.cardio => Colors.blue,
      ExerciseType.flexibility => Colors.green,
      ExerciseType.hiit => Colors.orange,
      ExerciseType.yoga => Colors.purple,
      ExerciseType.pilates => Colors.teal,
    };
  }

  IconData _getTypeIcon(ExerciseType type) {
    return switch (type) {
      ExerciseType.strength => Icons.fitness_center,
      ExerciseType.cardio => Icons.directions_run,
      ExerciseType.flexibility => Icons.self_improvement,
      ExerciseType.hiit => Icons.flash_on,
      ExerciseType.yoga => Icons.spa,
      ExerciseType.pilates => Icons.accessibility,
    };
  }
}