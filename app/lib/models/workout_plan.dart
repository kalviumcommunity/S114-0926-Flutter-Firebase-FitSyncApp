import 'package:cloud_firestore/cloud_firestore.dart';

enum ExerciseType { strength, cardio, flexibility, hiit, yoga, pilates }

class Exercise {
  final String id;
  final String name;
  final ExerciseType type;
  final String? description;
  final String? videoUrl;
  final String? imageUrl;
  final List<String> muscleGroups;
  final int? defaultSets;
  final int? defaultReps;
  final int? defaultDurationSeconds;
  final double? defaultWeight;

  Exercise({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.videoUrl,
    this.imageUrl,
    this.muscleGroups = const [],
    this.defaultSets,
    this.defaultReps,
    this.defaultDurationSeconds,
    this.defaultWeight,
  });

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      type: ExerciseType.values.byName(data['type'] ?? 'strength'),
      description: data['description'],
      videoUrl: data['videoUrl'],
      imageUrl: data['imageUrl'],
      muscleGroups: List<String>.from(data['muscleGroups'] ?? []),
      defaultSets: data['defaultSets'],
      defaultReps: data['defaultReps'],
      defaultDurationSeconds: data['defaultDurationSeconds'],
      defaultWeight: (data['defaultWeight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'description': description,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'muscleGroups': muscleGroups,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'defaultDurationSeconds': defaultDurationSeconds,
      'defaultWeight': defaultWeight,
    };
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final int? durationSeconds;
  final double? weight;
  final int restSeconds;
  final int order;
  final String? notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.durationSeconds,
    this.weight,
    this.restSeconds = 60,
    required this.order,
    this.notes,
  });

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      sets: map['sets'] ?? 3,
      reps: map['reps'] ?? 10,
      durationSeconds: map['durationSeconds'],
      weight: (map['weight'] as num?)?.toDouble(),
      restSeconds: map['restSeconds'] ?? 60,
      order: map['order'] ?? 0,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'weight': weight,
      'restSeconds': restSeconds,
      'order': order,
      'notes': notes,
    };
  }
}

enum WorkoutPlanStatus { draft, active, archived }

class WorkoutPlan {
  final String id;
  final String trainerId;
  final String trainerName;
  final String name;
  final String? description;
  final List<WorkoutExercise> exercises;
  final WorkoutPlanStatus status;
  final List<String> assignedMemberIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledStartDate;
  final int durationWeeks;

  WorkoutPlan({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.name,
    this.description,
    required this.exercises,
    this.status = WorkoutPlanStatus.draft,
    this.assignedMemberIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.scheduledStartDate,
    this.durationWeeks = 4,
  });

  factory WorkoutPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutPlan(
      id: doc.id,
      trainerId: data['trainerId'] ?? '',
      trainerName: data['trainerName'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      exercises: (data['exercises'] as List<dynamic>? ?? [])
          .map((e) => WorkoutExercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      status: WorkoutPlanStatus.values.byName(data['status'] ?? 'draft'),
      assignedMemberIds: List<String>.from(data['assignedMemberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      scheduledStartDate: data['scheduledStartDate'] != null
          ? (data['scheduledStartDate'] as Timestamp).toDate()
          : null,
      durationWeeks: data['durationWeeks'] ?? 4,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'trainerId': trainerId,
      'trainerName': trainerName,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'status': status.name,
      'assignedMemberIds': assignedMemberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'scheduledStartDate': scheduledStartDate != null
          ? Timestamp.fromDate(scheduledStartDate!)
          : null,
      'durationWeeks': durationWeeks,
    };
  }

  int get totalExercises => exercises.length;
  int get estimatedDurationMinutes => exercises.fold(0, (total, ex) {
        final setTime = ex.durationSeconds ?? (ex.reps * 5);
        return total + (ex.sets * (setTime + ex.restSeconds));
      }) ~/ 60;
}