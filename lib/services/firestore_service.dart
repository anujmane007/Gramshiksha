import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Management
  static Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String role,
    String? studentId,
    String? teacherId,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'studentId': studentId,
      'teacherId': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  // Course Management
  static Future<String> createCourse({
    required String title,
    required String description,
    required String instructor,
    required String teacherId,
    int totalLessons = 0,
  }) async {
    DocumentReference docRef = await _firestore.collection('courses').add({
      'title': title,
      'description': description,
      'instructor': instructor,
      'teacherId': teacherId,
      'totalLessons': totalLessons,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    return docRef.id;
  }

  static Future<void> enrollStudentInCourse(String studentId, String courseId) async {
    await _firestore.collection('students').doc(studentId).update({
      'coursesEnrolled': FieldValue.arrayUnion([courseId])
    });
  }

  // Quiz Management
  static Future<String> createQuiz({
    required String title,
    required String description,
    required String subject,
    required int duration,
    required int totalQuestions,
    required int maxScore,
    required String teacherId,
  }) async {
    DocumentReference docRef = await _firestore.collection('quizzes').add({
      'title': title,
      'description': description,
      'subject': subject,
      'duration': duration,
      'totalQuestions': totalQuestions,
      'maxScore': maxScore,
      'teacherId': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    return docRef.id;
  }

  static Future<void> addQuizQuestion({
    required String quizId,
    required String question,
    required List<String> options,
    required int correctAnswer,
  }) async {
    await _firestore.collection('quiz_questions').add({
      'quizId': quizId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Assignment Management
  static Future<String> createAssignment({
    required String title,
    required String description,
    required DateTime dueDate,
    required String teacherId,
    required String courseId,
    int maxScore = 100,
  }) async {
    DocumentReference docRef = await _firestore.collection('assignments').add({
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'teacherId': teacherId,
      'courseId': courseId,
      'maxScore': maxScore,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    return docRef.id;
  }

  // Announcement Management
  static Future<void> createAnnouncement({
    required String title,
    required String content,
    required String teacherId,
    String? targetAudience,
  }) async {
    await _firestore.collection('announcements').add({
      'title': title,
      'content': content,
      'teacherId': teacherId,
      'targetAudience': targetAudience ?? 'all',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  // Class Management
  static Future<String> createClass({
    required String name,
    required String subject,
    required String teacherId,
    List<String> students = const [],
  }) async {
    DocumentReference docRef = await _firestore.collection('classes').add({
      'name': name,
      'subject': subject,
      'teacherId': teacherId,
      'students': students,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    return docRef.id;
  }

  static Future<void> addStudentToClass(String classId, String studentId) async {
    await _firestore.collection('classes').doc(classId).update({
      'students': FieldValue.arrayUnion([studentId])
    });
  }

  // Attendance Management
  static Future<void> recordAttendance({
    required String classId,
    required String date,
    required Map<String, bool> attendance,
  }) async {
    await _firestore
        .collection('attendance')
        .doc('${classId}_$date')
        .set({
      'classId': classId,
      'date': date,
      'attendance': attendance,
      'recordedAt': FieldValue.serverTimestamp(),
      'recordedBy': _auth.currentUser?.uid,
    });
  }

  // Course Material Management
  static Future<void> addCourseMaterial({
    required String courseId,
    required String title,
    required String description,
    required String type, // video, pdf, document, audio
    required String url,
  }) async {
    await _firestore.collection('course_materials').add({
      'courseId': courseId,
      'title': title,
      'description': description,
      'type': type,
      'url': url,
      'uploadedAt': FieldValue.serverTimestamp(),
      'uploadedBy': _auth.currentUser?.uid,
    });
  }

  // Progress Tracking
  static Future<void> updateCourseProgress({
    required String studentId,
    required String courseId,
    required String lessonId,
  }) async {
    String progressId = '${studentId}_$courseId';
    
    DocumentReference progressRef = _firestore
        .collection('course_progress')
        .doc(progressId);
    
    DocumentSnapshot progressDoc = await progressRef.get();
    
    if (progressDoc.exists) {
      await progressRef.update({
        'completedLessons': FieldValue.arrayUnion([lessonId]),
        'lastAccessed': FieldValue.serverTimestamp(),
      });
    } else {
      await progressRef.set({
        'studentId': studentId,
        'courseId': courseId,
        'completedLessons': [lessonId],
        'startedAt': FieldValue.serverTimestamp(),
        'lastAccessed': FieldValue.serverTimestamp(),
      });
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getStudentStatistics(String studentId) async {
    try {
      // Get student data
      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        return {
          'totalScore': 0,
          'quizzesTaken': 0,
          'assignmentsSubmitted': 0,
          'coursesEnrolled': 0,
        };
      }

      Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
      
      return {
        'totalScore': studentData['totalScore'] ?? 0,
        'quizzesTaken': studentData['quizzesTaken'] ?? 0,
        'assignmentsSubmitted': studentData['assignmentsSubmitted'] ?? 0,
        'coursesEnrolled': (studentData['coursesEnrolled'] as List?)?.length ?? 0,
        'achievements': studentData['achievements'] ?? [],
      };
    } catch (e) {
      print('Error getting student statistics: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getTeacherStatistics(String teacherId) async {
    try {
      // Count classes
      QuerySnapshot classesSnapshot = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      // Count total students across all classes
      int totalStudents = 0;
      for (var doc in classesSnapshot.docs) {
        Map<String, dynamic> classData = doc.data() as Map<String, dynamic>;
        List<dynamic> students = classData['students'] ?? [];
        totalStudents += students.length;
      }

      // Count assignments
      QuerySnapshot assignmentsSnapshot = await _firestore
          .collection('assignments')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      // Count quizzes
      QuerySnapshot quizzesSnapshot = await _firestore
          .collection('quizzes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      return {
        'totalClasses': classesSnapshot.docs.length,
        'totalStudents': totalStudents,
        'totalAssignments': assignmentsSnapshot.docs.length,
        'totalQuizzes': quizzesSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting teacher statistics: $e');
      return {};
    }
  }
}