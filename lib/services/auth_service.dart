import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    required String role, // "student" or "teacher"
  }) async {
    try {
      // Create user account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(fullName);

      // Store user details in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'fullName': fullName,
        'studentId': role == 'student' ? studentId : null,
        'teacherId': role == 'teacher' ? studentId : null,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'profilePhotoUrl': null,
        'isActive': true,
      });

      // Initialize student-specific data
      if (role == 'student') {
        await _firestore.collection('students').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'totalScore': 0,
          'quizzesTaken': 0,
          'assignmentsSubmitted': 0,
          'coursesEnrolled': [],
          'achievements': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Initialize teacher-specific data
      if (role == 'teacher') {
        await _firestore.collection('teachers').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'subjectsTeaching': [],
          'classesManaging': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return result;
    } catch (e) {
      print('Error signing up: $e');
      throw e;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result;
    } catch (e) {
      print('Error signing in: $e');
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      throw e;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    if (_auth.currentUser == null) return null;

    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    if (_auth.currentUser == null) return null;

    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? profilePhotoUrl,
  }) async {
    if (_auth.currentUser == null) return;

    try {
      Map<String, dynamic> updates = {};

      if (fullName != null) {
        updates['fullName'] = fullName;
        await _auth.currentUser!.updateDisplayName(fullName);
      }

      if (profilePhotoUrl != null) {
        updates['profilePhotoUrl'] = profilePhotoUrl;
        await _auth.currentUser!.updatePhotoURL(profilePhotoUrl);
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update(updates);
      }

      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }
}
