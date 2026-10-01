import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user.dart';
import 'package:app/models/workout_plan.dart';
import 'package:app/models/progress_log.dart';
import 'package:app/models/branch.dart';

/// Test utilities and mock data for integration tests

/// Creates a test member user
AppUser createTestMember({
  String? uid,
  String email = 'testmember@test.com',
  String displayName = 'Test Member',
  String? branchId,
  String? trainerId,
}) {
  return AppUser(
    uid: uid ?? 'test-member-${DateTime.now().millisecondsSinceEpoch}',
    email: email,
    displayName: displayName,
    role: UserRole.member,
    branchId: branchId,
    trainerId: trainerId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Creates a test trainer user
AppUser createTestTrainer({
  String? uid,
  String email = 'testtrainer@test.com',
  String displayName = 'Test Trainer',
  String? branchId,
}) {
  return AppUser(
    uid: uid ?? 'test-trainer-${DateTime.now().millisecondsSinceEpoch}',
    email: email,
    displayName: displayName,
    role: UserRole.trainer,
    branchId: branchId,
    memberIds: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Creates a test admin user
AppUser createTestAdmin({
  String? uid,
  String email = 'testadmin@test.com',
  String displayName = 'Test Admin',
}) {
  return AppUser(
    uid: uid ?? 'test-admin-${DateTime.now().millisecondsSinceEpoch}',
    email: email,
    displayName: displayName,
    role: UserRole.admin,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Creates a test branch
Branch createTestBranch({
  String? id,
  String name = 'Test Branch',
  String address = '123 Test St, Test City',
  String? phone = '555-1234',
  String? email = 'branch@test.com',
  String? managerId,
  bool isActive = true,
}) {
  return Branch(
    id: id ?? 'branch-${DateTime.now().millisecondsSinceEpoch}',
    name: name,
    address: address,
    phone: phone,
    email: email,
    managerId: managerId,
    trainerIds: [],
    memberIds: [],
    isActive: isActive,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Creates a test exercise
Exercise createTestExercise({
  String? id,
  String name = 'Test Exercise',
  ExerciseType type = ExerciseType.strength,
  List<String> muscleGroups = const ['chest', 'triceps'],
  int? defaultSets = 3,
  int? defaultReps = 10,
  int? defaultDurationSeconds,
  double? defaultWeight,
}) {
  return Exercise(
    id: id ?? 'exercise-${DateTime.now().millisecondsSinceEpoch}',
    name: name,
    type: type,
    muscleGroups: muscleGroups,
    defaultSets: defaultSets,
    defaultReps: defaultReps,
    defaultDurationSeconds: defaultDurationSeconds,
    defaultWeight: defaultWeight,
  );
}

/// Creates a test workout plan
WorkoutPlan createTestWorkoutPlan({
  String? id,
  required String trainerId,
  required String trainerName,
  String name = 'Test Workout Plan',
  String? description,
  List<WorkoutExercise> exercises = const [],
  WorkoutPlanStatus status = WorkoutPlanStatus.active,
  List<String> assignedMemberIds = const [],
  int durationWeeks = 4,
}) {
  return WorkoutPlan(
    id: id ?? 'plan-${DateTime.now().millisecondsSinceEpoch}',
    trainerId: trainerId,
    trainerName: trainerName,
    name: name,
    description: description,
    exercises: exercises,
    status: status,
    assignedMemberIds: assignedMemberIds,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    durationWeeks: durationWeeks,
  );
}

/// Creates a test workout exercise
WorkoutExercise createTestWorkoutExercise({
  String? exerciseId,
  String exerciseName = 'Push-ups',
  int sets = 3,
  int reps = 15,
  int? durationSeconds,
  double? weight,
  int restSeconds = 60,
  int order = 0,
  String? notes,
}) {
  return WorkoutExercise(
    exerciseId: exerciseId ?? 'exercise-${DateTime.now().millisecondsSinceEpoch}',
    exerciseName: exerciseName,
    sets: sets,
    reps: reps,
    durationSeconds: durationSeconds,
    weight: weight,
    restSeconds: restSeconds,
    order: order,
    notes: notes,
  );
}

/// Creates a test progress log
ProgressLog createTestProgressLog({
  String? id,
  required String memberId,
  required String memberName,
  String? trainerId,
  String? workoutPlanId,
  LogType type = LogType.workout,
  String? workoutName,
  List<CompletedExercise>? completedExercises,
  int? durationMinutes,
  double? caloriesBurned,
  String? notes,
  int? difficultyRating,
  double? weightKg,
  double? bodyFatPercentage,
  Map<String, double>? measurements,
  List<String>? photoUrls,
}) {
  return ProgressLog(
    id: id ?? 'log-${DateTime.now().millisecondsSinceEpoch}',
    memberId: memberId,
    memberName: memberName,
    trainerId: trainerId,
    workoutPlanId: workoutPlanId,
    type: type,
    date: DateTime.now(),
    workoutName: workoutName,
    completedExercises: completedExercises,
    durationMinutes: durationMinutes,
    caloriesBurned: caloriesBurned,
    notes: notes,
    difficultyRating: difficultyRating,
    weightKg: weightKg,
    bodyFatPercentage: bodyFatPercentage,
    measurements: measurements,
    photoUrls: photoUrls,
    createdAt: DateTime.now(),
  );
}

/// Creates a completed exercise for testing
CompletedExercise createTestCompletedExercise({
  String exerciseId = 'exercise-1',
  String exerciseName = 'Push-ups',
  List<CompletedSet> sets = const [],
  String? notes,
}) {
  return CompletedExercise(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets,
    notes: notes,
  );
}

/// Creates a completed set for testing
CompletedSet createTestCompletedSet({
  int setNumber = 1,
  int? reps = 15,
  double? weight,
  int? durationSeconds,
  bool completed = true,
}) {
  return CompletedSet(
    setNumber: setNumber,
    reps: reps,
    weight: weight,
    durationSeconds: durationSeconds,
    completed: completed,
  );
}

/// Helper to pump widget and wait for animations
Future<void> pumpAndSettle(WidgetTester tester, {Duration? duration}) async {
  await tester.pumpAndSettle(duration ?? const Duration(seconds: 1));
}

/// Helper to find widget by key
Finder findByKey(Key key) {
  return find.byKey(key);
}

/// Helper to find widget by text
Finder findByText(String text, {bool skipOffstage = false}) {
  return find.text(text, skipOffstage: skipOffstage);
}

/// Helper to find widget by type
Finder findByType(Type type) {
  return find.byType(type);
}

/// Helper to tap widget and settle
Future<void> tapAndSettle(WidgetTester tester, Finder finder, {Duration? duration}) async {
  await tester.tap(finder);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Helper to enter text and settle
Future<void> enterTextAndSettle(WidgetTester tester, Finder finder, String text, {Duration? duration}) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle(duration ?? const Duration(seconds: 1));
}

/// Helper to verify widget exists
void expectExists(Finder finder) {
  expect(finder, findsOneWidget);
}

/// Helper to verify widget does not exist
void expectNotExists(Finder finder) {
  expect(finder, findsNothing);
}

/// Helper to wait for async operations
Future<void> waitForAsync({Duration duration = const Duration(seconds: 2)}) async {
  await Future.delayed(duration);
}