import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'quiz_creation_page.dart';
import 'assignment_creation_page.dart';
import 'course_creation_page.dart';

class TeacherHomePage extends StatefulWidget {
  final Function(int)? onTabChange;

  const TeacherHomePage({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 20),

            // Statistics Overview
            _buildStatisticsOverview(),
            const SizedBox(height: 20),

            // Recent Activities
            _buildRecentActivities(),
            const SizedBox(height: 20),

            // Upcoming Events
            _buildUpcomingEvents(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickActionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Quick Action'),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            _auth.currentUser?.displayName ?? 'Teacher',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to inspire and educate today?',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Create Quiz',
                Icons.quiz,
                Colors.blue,
                () => _createQuiz(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Assignment',
                Icons.assignment,
                Colors.green,
                () => _createAssignment(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Announcement',
                Icons.announcement,
                Colors.orange,
                () => _createAnnouncement(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Take Attendance',
                Icons.people,
                Colors.purple,
                () => _takeAttendance(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('classes')
                  .where('teacherId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
          builder: (context, snapshot) {
            int totalClasses =
                snapshot.hasData ? snapshot.data!.docs.length : 0;

            return Row(
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
                Expanded(child: _buildStudentCountCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildAssignmentCountCard()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentCountCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('classes')
              .where('teacherId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
      builder: (context, snapshot) {
        int totalStudents = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> classData = doc.data() as Map<String, dynamic>;
            List<dynamic> students = classData['students'] ?? [];
            totalStudents += students.length;
          }
        }

        return _buildStatCard(
          'Students',
          '$totalStudents',
          Icons.people,
          Colors.green,
        );
      },
    );
  }

  Widget _buildAssignmentCountCard() {
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('quiz_results')
                  .orderBy('completedAt', descending: true)
                  .limit(5)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent activities'),
                ),
              );
            }

            return Card(
              child: Column(
                children:
                    snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> result =
                          doc.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: const Icon(Icons.quiz, color: Colors.blue),
                        title: Text('${result['quizTitle']} completed'),
                        subtitle: FutureBuilder<DocumentSnapshot>(
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
                              );
                            }
                            return const Text('by Student');
                          },
                        ),
                        trailing: Text(
                          '${result['score']}/${result['totalQuestions']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Events',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('assignments')
                  .where('teacherId', isEqualTo: _auth.currentUser?.uid)
                  .where('dueDate', isGreaterThan: Timestamp.now())
                  .orderBy('dueDate')
                  .limit(3)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No upcoming events'),
                ),
              );
            }

            return Card(
              child: Column(
                children:
                    snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> assignment =
                          doc.data() as Map<String, dynamic>;
                      Timestamp dueDate = assignment['dueDate'];

                      return ListTile(
                        leading: const Icon(Icons.event, color: Colors.green),
                        title: Text('${assignment['title']} due'),
                        subtitle: Text('Due: ${_formatDate(dueDate.toDate())}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to assignment details
                        },
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showQuickActionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quick Actions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.book, color: Colors.teal),
                  title: const Text('Create Course'),
                  onTap: () {
                    Navigator.pop(context);
                    _createCourse();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.quiz, color: Colors.blue),
                  title: const Text('Create Quiz'),
                  onTap: () {
                    Navigator.pop(context);
                    _createQuiz();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.green),
                  title: const Text('Create Assignment'),
                  onTap: () {
                    Navigator.pop(context);
                    _createAssignment();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.announcement, color: Colors.orange),
                  title: const Text('Make Announcement'),
                  onTap: () {
                    Navigator.pop(context);
                    _createAnnouncement();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.purple),
                  title: const Text('Take Attendance'),
                  onTap: () {
                    Navigator.pop(context);
                    _takeAttendance();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _createCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CourseCreationPage()),
    );
  }

  void _createQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizCreationPage()),
    );
  }

  void _createAssignment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AssignmentCreationPage()),
    );
  }

  void _createAnnouncement() {
    // Navigate to announcements tab
    if (widget.onTabChange != null) {
      widget.onTabChange!(2); // Index for announcements tab
    }
  }

  void _takeAttendance() {
    // Navigate to attendance tab
    if (widget.onTabChange != null) {
      widget.onTabChange!(1); // Index for attendance tab
    }
  }
}
