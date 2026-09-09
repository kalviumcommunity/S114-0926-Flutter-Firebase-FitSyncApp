import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

enum UserRole { member, trainer, admin }

extension UserRoleX on UserRole {
  String get name => switch (this) {
        UserRole.member => 'member',
        UserRole.trainer => 'trainer',
        UserRole.admin => 'admin',
      };
  
  static UserRole fromString(String value) => switch (value) {
        'trainer' => UserRole.trainer,
        'admin' => UserRole.admin,
        _ => UserRole.member,
      };
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? branchId;
  final String? trainerId; // For members: their assigned trainer
  final List<String> memberIds; // For trainers: their assigned members
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.branchId,
    this.trainerId,
    this.memberIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRoleX.fromString(data['role'] ?? 'member'),
      branchId: data['branchId'],
      trainerId: data['trainerId'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory AppUser.fromFirebaseAuth(fb_auth.User user, {UserRole role = UserRole.member}) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'branchId': branchId,
      'trainerId': trainerId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    UserRole? role,
    String? branchId,
    String? trainerId,
    List<String>? memberIds,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      trainerId: trainerId ?? this.trainerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isTrainer => role == UserRole.trainer;
  bool get isAdmin => role == UserRole.admin;
  bool get isMember => role == UserRole.member;
}