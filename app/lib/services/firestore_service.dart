import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../models/workout_plan.dart';
import '../models/progress_log.dart';
import '../models/branch.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _workoutPlans => _firestore.collection('workoutPlans');
  CollectionReference get _progressLogs => _firestore.collection('progressLogs');
  CollectionReference get _branches => _firestore.collection('branches');
  CollectionReference get _exercises => _firestore.collection('exercises');
  CollectionReference get _assignments => _firestore.collection('memberAssignments');

  // ========== USER OPERATIONS ==========
  
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists) return AppUser.fromFirestore(doc);
    return null;
  }

  Stream<AppUser> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) => AppUser.fromFirestore(doc));
  }

  Future<void> updateUser(AppUser user) async {
    await _users.doc(user.uid).update(user.toFirestore());
  }

  // ========== WORKOUT PLAN OPERATIONS ==========

  Future<WorkoutPlan> createWorkoutPlan(WorkoutPlan plan) async {
    final doc = await _workoutPlans.add(plan.toFirestore());
    return plan.copyWith(id: doc.id);
  }

  Future<WorkoutPlan?> getWorkoutPlan(String id) async {
    final doc = await _workoutPlans.doc(id).get();
    if (doc.exists) return WorkoutPlan.fromFirestore(doc);
    return null;
  }

  Stream<List<WorkoutPlan>> watchTrainerWorkoutPlans(String trainerId) {
    return _workoutPlans
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WorkoutPlan.fromFirestore(doc)).toList());
  }

  Stream<List<WorkoutPlan>> watchMemberWorkoutPlans(String memberId) {
    return _workoutPlans
        .where('assignedMemberIds', arrayContains: memberId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WorkoutPlan.fromFirestore(doc)).toList());
  }

  Future<void> updateWorkoutPlan(WorkoutPlan plan) async {
    await _workoutPlans.doc(plan.id).update(plan.toFirestore());
  }

  Future<void> assignWorkoutPlanToMember(String planId, String memberId) async {
    await _workoutPlans.doc(planId).update({
      'assignedMemberIds': FieldValue.arrayUnion([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unassignWorkoutPlanFromMember(String planId, String memberId) async {
    await _workoutPlans.doc(planId).update({
      'assignedMemberIds': FieldValue.arrayRemove([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== PROGRESS LOG OPERATIONS ==========

  Future<ProgressLog> createProgressLog(ProgressLog log) async {
    final doc = await _progressLogs.add(log.toFirestore());
    return log.copyWith(id: doc.id);
  }

  Stream<List<ProgressLog>> watchMemberProgressLogs(String memberId, {int limit = 50}) {
    return _progressLogs
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProgressLog.fromFirestore(doc)).toList());
  }

  Stream<List<ProgressLog>> watchTrainerMemberProgressLogs(String trainerId, {int limit = 100}) {
    return _progressLogs
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProgressLog.fromFirestore(doc)).toList());
  }

  // ========== BRANCH OPERATIONS ==========

  Future<Branch> createBranch(Branch branch) async {
    final doc = await _branches.add(branch.toFirestore());
    return branch.copyWith(id: doc.id);
  }

  Future<Branch?> getBranch(String id) async {
    final doc = await _branches.doc(id).get();
    if (doc.exists) return Branch.fromFirestore(doc);
    return null;
  }

  Stream<List<Branch>> watchBranches() {
    return _branches
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Branch.fromFirestore(doc)).toList());
  }

  Future<void> updateBranch(Branch branch) async {
    await _branches.doc(branch.id).update(branch.toFirestore());
  }

  Future<void> addTrainerToBranch(String branchId, String trainerId) async {
    await _branches.doc(branchId).update({
      'trainerIds': FieldValue.arrayUnion([trainerId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeTrainerFromBranch(String branchId, String trainerId) async {
    await _branches.doc(branchId).update({
      'trainerIds': FieldValue.arrayRemove([trainerId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMemberToBranch(String branchId, String memberId) async {
    await _branches.doc(branchId).update({
      'memberIds': FieldValue.arrayUnion([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeMemberFromBranch(String branchId, String memberId) async {
    await _branches.doc(branchId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== MEMBER ASSIGNMENT OPERATIONS ==========

  Future<MemberAssignment> createAssignment(MemberAssignment assignment) async {
    final doc = await _assignments.add(assignment.toFirestore());
    return assignment.copyWith(id: doc.id);
  }

  Stream<List<MemberAssignment>> watchMemberAssignments(String memberId) {
    return _assignments
        .where('memberId', isEqualTo: memberId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MemberAssignment.fromFirestore(doc)).toList());
  }

  Stream<List<MemberAssignment>> watchBranchAssignments(String branchId) {
    return _assignments
        .where('branchId', isEqualTo: branchId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MemberAssignment.fromFirestore(doc)).toList());
  }

  Future<void> transferMember({
    required String memberId,
    required String memberName,
    required String newTrainerId,
    required String newTrainerName,
    required String newBranchId,
    required String newBranchName,
    required String previousTrainerId,
    required String previousBranchId,
  }) async {
    // End current assignment
    final currentAssignments = await _assignments
        .where('memberId', isEqualTo: memberId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in currentAssignments.docs) {
      await doc.reference.update({
        'status': 'transferred',
        'reassignedAt': FieldValue.serverTimestamp(),
      });
    }

    // Create new assignment
    final newAssignment = MemberAssignment(
      id: '', // Will be set by Firestore
      memberId: memberId,
      memberName: memberName,
      trainerId: newTrainerId,
      trainerName: newTrainerName,
      branchId: newBranchId,
      branchName: newBranchName,
      assignedAt: DateTime.now(),
      previousTrainerId: previousTrainerId,
      previousBranchId: previousBranchId,
    );
    await createAssignment(newAssignment);

    // Update user document
    await _users.doc(memberId).update({
      'trainerId': newTrainerId,
      'branchId': newBranchId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update trainer's member lists
    await _users.doc(previousTrainerId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _users.doc(newTrainerId).update({
      'memberIds': FieldValue.arrayUnion([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update branch member lists
    await _branches.doc(previousBranchId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _branches.doc(newBranchId).update({
      'memberIds': FieldValue.arrayUnion([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== EXERCISE OPERATIONS ==========

  Stream<List<Exercise>> watchExercises() {
    return _exercises.orderBy('name').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList(),
    );
  }

  Future<void> seedExercises() async {
    final exercises = [
      Exercise(id: '', name: 'Push-ups', type: ExerciseType.strength, muscleGroups: ['chest', 'triceps', 'shoulders'], defaultSets: 3, defaultReps: 15),
      Exercise(id: '', name: 'Squats', type: ExerciseType.strength, muscleGroups: ['quads', 'glutes'], defaultSets: 3, defaultReps: 15),
      Exercise(id: '', name: 'Deadlifts', type: ExerciseType.strength, muscleGroups: ['back', 'hamstrings', 'glutes'], defaultSets: 3, defaultReps: 10),
      Exercise(id: '', name: 'Plank', type: ExerciseType.strength, muscleGroups: ['core'], defaultDurationSeconds: 60),
      Exercise(id: '', name: 'Running', type: ExerciseType.cardio, muscleGroups: ['legs', 'cardio'], defaultDurationSeconds: 1800),
      Exercise(id: '', name: 'Cycling', type: ExerciseType.cardio, muscleGroups: ['legs', 'cardio'], defaultDurationSeconds: 1800),
      Exercise(id: '', name: 'Yoga Flow', type: ExerciseType.yoga, muscleGroups: ['full body'], defaultDurationSeconds: 1800),
      Exercise(id: '', name: 'Burpees', type: ExerciseType.hiit, muscleGroups: ['full body'], defaultSets: 3, defaultReps: 10),
      Exercise(id: '', name: 'Pull-ups', type: ExerciseType.strength, muscleGroups: ['back', 'biceps'], defaultSets: 3, defaultReps: 8),
      Exercise(id: '', name: 'Lunges', type: ExerciseType.strength, muscleGroups: ['quads', 'glutes'], defaultSets: 3, defaultReps: 12),
    ];

    final batch = _firestore.batch();
    for (final exercise in exercises) {
      final doc = _exercises.doc();
      batch.set(doc, exercise.toFirestore());
    }
    await batch.commit();
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AppUser>> getTrainers({String? branchId}) async {
    Query query = _users.where('role', isEqualTo: 'trainer').where('isActive', isEqualTo: true);
    if (branchId != null) query = query.where('branchId', isEqualTo: branchId);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  Future<List<AppUser>> getMembers({String? trainerId, String? branchId}) async {
    Query query = _users.where('role', isEqualTo: 'member').where('isActive', isEqualTo: true);
    if (trainerId != null) query = query.where('trainerId', isEqualTo: trainerId);
    if (branchId != null) query = query.where('branchId', isEqualTo: branchId);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }
}

// Add copyWith to ProgressLog
extension ProgressLogCopyWith on ProgressLog {
  ProgressLog copyWith({String? id}) {
    return ProgressLog(
      id: id ?? this.id,
      memberId: memberId,
      memberName: memberName,
      trainerId: trainerId,
      workoutPlanId: workoutPlanId,
      type: type,
      date: date,
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
      createdAt: createdAt,
    );
  }
}

// Add copyWith to WorkoutPlan
extension WorkoutPlanCopyWith on WorkoutPlan {
  WorkoutPlan copyWith({String? id}) {
    return WorkoutPlan(
      id: id ?? this.id,
      trainerId: trainerId,
      trainerName: trainerName,
      name: name,
      description: description,
      exercises: exercises,
      status: status,
      assignedMemberIds: assignedMemberIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      scheduledStartDate: scheduledStartDate,
      durationWeeks: durationWeeks,
    );
  }
}

// Add copyWith to MemberAssignment
extension MemberAssignmentCopyWith on MemberAssignment {
  MemberAssignment copyWith({String? id}) {
    return MemberAssignment(
      id: id ?? this.id,
      memberId: memberId,
      memberName: memberName,
      trainerId: trainerId,
      trainerName: trainerName,
      branchId: branchId,
      branchName: branchName,
      assignedAt: assignedAt,
      reassignedAt: reassignedAt,
      previousTrainerId: previousTrainerId,
      previousBranchId: previousBranchId,
      status: status,
      notes: notes,
    );
  }
}

// Providers
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final exercisesStreamProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(firestoreServiceProvider).watchExercises();
});

final trainerWorkoutPlansProvider = StreamProvider.family<List<WorkoutPlan>, String>((ref, trainerId) {
  return ref.watch(firestoreServiceProvider).watchTrainerWorkoutPlans(trainerId);
});

final memberWorkoutPlansProvider = StreamProvider.family<List<WorkoutPlan>, String>((ref, memberId) {
  return ref.watch(firestoreServiceProvider).watchMemberWorkoutPlans(memberId);
});

final memberProgressLogsProvider = StreamProvider.family<List<ProgressLog>, String>((ref, memberId) {
  return ref.watch(firestoreServiceProvider).watchMemberProgressLogs(memberId, limit: 50);
});

final trainerMemberProgressLogsProvider = StreamProvider.family<List<ProgressLog>, String>((ref, trainerId) {
  return ref.watch(firestoreServiceProvider).watchTrainerMemberProgressLogs(trainerId, limit: 100);
});

final branchesStreamProvider = StreamProvider<List<Branch>>((ref) {
  return ref.watch(firestoreServiceProvider).watchBranches();
});