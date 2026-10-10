import 'package:cloud_firestore/cloud_firestore.dart';

enum LogType { workout, measurement, photo, note }

class ProgressLog {
  final String id;
  final String memberId;
  final String memberName;
  final String? trainerId;
  final String? workoutPlanId;
  final LogType type;
  final DateTime date;
  
  // Workout log fields
  final String? workoutName;
  final List<CompletedExercise>? completedExercises;
  final int? durationMinutes;
  final double? caloriesBurned;
  final String? notes;
  final int? difficultyRating; // 1-10
  
  // Measurement fields
  final double? weightKg;
  final double? bodyFatPercentage;
  final Map<String, double>? measurements; // e.g., {'chest': 100, 'waist': 85}
  
  // Photo fields
  final List<String>? photoUrls;
  
  final DateTime createdAt;

  ProgressLog({
    required this.id,
    required this.memberId,
    required this.memberName,
    this.trainerId,
    this.workoutPlanId,
    required this.type,
    required this.date,
    this.workoutName,
    this.completedExercises,
    this.durationMinutes,
    this.caloriesBurned,
    this.notes,
    this.difficultyRating,
    this.weightKg,
    this.bodyFatPercentage,
    this.measurements,
    this.photoUrls,
    required this.createdAt,
  });

  factory ProgressLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgressLog(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      trainerId: data['trainerId'],
      workoutPlanId: data['workoutPlanId'],
      type: LogType.values.byName(data['type'] ?? 'workout'),
      date: (data['date'] as Timestamp).toDate(),
      workoutName: data['workoutName'],
      completedExercises: (data['completedExercises'] as List<dynamic>? ?? [])
          .map((e) => CompletedExercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      durationMinutes: data['durationMinutes'],
      caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble(),
      notes: data['notes'],
      difficultyRating: data['difficultyRating'],
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      bodyFatPercentage: (data['bodyFatPercentage'] as num?)?.toDouble(),
      measurements: data['measurements'] != null
          ? Map<String, double>.from(
              (data['measurements'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble())))
          : null,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'trainerId': trainerId,
      'workoutPlanId': workoutPlanId,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'workoutName': workoutName,
      'completedExercises': completedExercises?.map((e) => e.toMap()).toList(),
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'notes': notes,
      'difficultyRating': difficultyRating,
      'weightKg': weightKg,
      'bodyFatPercentage': bodyFatPercentage,
      'measurements': measurements,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class CompletedExercise {
  final String exerciseId;
  final String exerciseName;
  final List<CompletedSet> sets;
  final String? notes;

  CompletedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes,
  });

  factory CompletedExercise.fromMap(Map<String, dynamic> map) {
    return CompletedExercise(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      sets: (map['sets'] as List<dynamic>? ?? [])
          .map((e) => CompletedSet.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((e) => e.toMap()).toList(),
      'notes': notes,
    };
  }
}

class CompletedSet {
  final int setNumber;
  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final bool completed;

  CompletedSet({
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.completed = true,
  });

  factory CompletedSet.fromMap(Map<String, dynamic> map) {
    return CompletedSet(
      setNumber: map['setNumber'] ?? 1,
      reps: map['reps'],
      weight: (map['weight'] as num?)?.toDouble(),
      durationSeconds: map['durationSeconds'],
      completed: map['completed'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'durationSeconds': durationSeconds,
      'completed': completed,
    };
  }
}