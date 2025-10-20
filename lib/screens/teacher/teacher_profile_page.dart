import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({Key? key}) : super(key: key);

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _teacherIdController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _teacherIdController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_auth.currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _fullNameController.text = userData['fullName'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _teacherIdController.text = userData['teacherId'] ?? '';
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).updateUserProfile(fullName: _fullNameController.text.trim());

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'fullName': _fullNameController.text.trim(),
        'teacherId': _teacherIdController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // Reset form when cancelling edit
                  _loadUserData();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 32),

            // Profile Form
            _buildProfileForm(),
            const SizedBox(height: 32),

            // Teaching Statistics
            _buildTeachingStatistics(),
            const SizedBox(height: 32),

            // Recent Activities
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              _auth.currentUser?.displayName?.substring(0, 1).toUpperCase() ??
                  'T',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _auth.currentUser?.displayName ?? 'Teacher',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _auth.currentUser?.email ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Teacher',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Full Name
            CustomTextField(
              controller: _fullNameController,
              label: 'Full Name',
              prefixIcon: Icons.person,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),

            // Email (read-only)
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              prefixIcon: Icons.email,
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Teacher ID
            CustomTextField(
              controller: _teacherIdController,
              label: 'Teacher ID',
              prefixIcon: Icons.badge,
              enabled: _isEditing,
            ),

            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _loadUserData();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      isLoading: _isLoading,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('classes')
              .where('teacherId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
      builder: (context, snapshot) {
        int totalClasses = 0;
        int totalStudents = 0;

        if (snapshot.hasData) {
          totalClasses = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> classData = doc.data() as Map<String, dynamic>;
            List<dynamic> students = classData['students'] ?? [];
            totalStudents += students.length;
          }
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teaching Statistics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Classes',
                        '$totalClasses',
                        Icons.class_,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Students',
                        '$totalStudents',
                        Icons.people,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildAssignmentStatCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildQuizStatCard()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentStatCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('assignments')
              .where('teacherId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
      builder: (context, snapshot) {
        int totalAssignments =
            snapshot.hasData ? snapshot.data!.docs.length : 0;

        return _buildStatCard(
          'Assignments',
          '$totalAssignments',
          Icons.assignment,
          Colors.orange,
        );
      },
    );
  }

  Widget _buildQuizStatCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('quizzes')
              .where('teacherId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
      builder: (context, snapshot) {
        int totalQuizzes = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return _buildStatCard(
          'Quizzes',
          '$totalQuizzes',
          Icons.quiz,
          Colors.purple,
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('quiz_results')
                      .orderBy('completedAt', descending: true)
                      .limit(5)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent activities'));
                }

                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        Map<String, dynamic> result =
                            doc.data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.quiz, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${result['quizTitle']} completed',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    FutureBuilder<DocumentSnapshot>(
                                      future:
                                          _firestore
                                              .collection('users')
                                              .doc(result['studentId'])
                                              .get(),
                                      builder: (context, userSnapshot) {
                                        if (userSnapshot.hasData &&
                                            userSnapshot.data!.exists) {
                                          Map<String, dynamic> userData =
                                              userSnapshot.data!.data()
                                                  as Map<String, dynamic>;
                                          return Text(
                                            'by ${userData['fullName'] ?? 'Student'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        }
                                        return const Text('by Student');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${result['score']}/${result['totalQuestions']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
