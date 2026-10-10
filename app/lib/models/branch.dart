import 'package:cloud_firestore/cloud_firestore.dart';

class Branch {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? managerId;
  final List<String> trainerIds;
  final List<String> memberIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings; // operating hours, amenities, etc.

  Branch({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.managerId,
    this.trainerIds = const [],
    this.memberIds = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  factory Branch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Branch(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'],
      email: data['email'],
      managerId: data['managerId'],
      trainerIds: List<String>.from(data['trainerIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      settings: data['settings'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'managerId': managerId,
      'trainerIds': trainerIds,
      'memberIds': memberIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'settings': settings,
    };
  }

  Branch copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? managerId,
    List<String>? trainerIds,
    List<String>? memberIds,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      managerId: managerId ?? this.managerId,
      trainerIds: trainerIds ?? this.trainerIds,
      memberIds: memberIds ?? this.memberIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      settings: settings ?? this.settings,
    );
  }
}

class MemberAssignment {
  final String id;
  final String memberId;
  final String memberName;
  final String trainerId;
  final String trainerName;
  final String branchId;
  final String branchName;
  final DateTime assignedAt;
  final DateTime? reassignedAt;
  final String? previousTrainerId;
  final String? previousBranchId;
  final AssignmentStatus status;
  final String? notes;

  MemberAssignment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.trainerId,
    required this.trainerName,
    required this.branchId,
    required this.branchName,
    required this.assignedAt,
    this.reassignedAt,
    this.previousTrainerId,
    this.previousBranchId,
    this.status = AssignmentStatus.active,
    this.notes,
  });

  factory MemberAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberAssignment(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      trainerId: data['trainerId'] ?? '',
      trainerName: data['trainerName'] ?? '',
      branchId: data['branchId'] ?? '',
      branchName: data['branchName'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp).toDate(),
      reassignedAt: data['reassignedAt'] != null
          ? (data['reassignedAt'] as Timestamp).toDate()
          : null,
      previousTrainerId: data['previousTrainerId'],
      previousBranchId: data['previousBranchId'],
      status: AssignmentStatus.values.byName(data['status'] ?? 'active'),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'branchId': branchId,
      'branchName': branchName,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'reassignedAt': reassignedAt != null ? Timestamp.fromDate(reassignedAt!) : null,
      'previousTrainerId': previousTrainerId,
      'previousBranchId': previousBranchId,
      'status': status.name,
      'notes': notes,
    };
  }
}

enum AssignmentStatus { active, transferred, ended }