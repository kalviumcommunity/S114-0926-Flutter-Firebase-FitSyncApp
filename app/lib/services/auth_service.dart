import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  fb_auth.User? get currentUser => _auth.currentUser;

  Future<fb_auth.UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<fb_auth.UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    UserRole role,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    // Create user document in Firestore
    final appUser = AppUser.fromFirebaseAuth(credential.user!, role: role);
    await _firestore.collection('users').doc(credential.user!.uid).set(appUser.toFirestore());

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    if (_auth.currentUser != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> setCustomUserRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Stream provider for current user
final authStateProvider = StreamProvider<fb_auth.User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Provider for current AppUser (with role)
final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  
  return authService.authStateChanges.asyncMap((fbUser) async {
    if (fbUser == null) return null;
    
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(fbUser.uid)
        .get();
    
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    } else {
      // Create user doc if missing
      final appUser = AppUser.fromFirebaseAuth(fbUser);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .set(appUser.toFirestore());
      return appUser;
    }
  });
});