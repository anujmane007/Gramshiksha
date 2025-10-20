import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({Key? key}) : super(key: key);

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _firestore
                .collection('students')
                .doc(_auth.currentUser?.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> studentData =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          List<dynamic> enrolledCourses = studentData['coursesEnrolled'] ?? [];

          if (enrolledCourses.isEmpty) {
            return _buildEmptyState();
          }

          return StreamBuilder<QuerySnapshot>(
            stream:
                _firestore
                    .collection('courses')
                    .where(
                      FieldPath.documentId,
                      whereIn: enrolledCourses.take(10).toList(),
                    )
                    .snapshots(),
            builder: (context, courseSnapshot) {
              if (!courseSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courseSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot doc = courseSnapshot.data!.docs[index];
                  Map<String, dynamic> course =
                      doc.data() as Map<String, dynamic>;

                  return _buildCourseCard(doc.id, course);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEnrollDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No courses enrolled yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to enroll in a course',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(String courseId, Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _navigateToCourseDetails(courseId, course);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      (course['title'] ?? 'C').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['title'] ?? 'Course Title',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By ${course['instructor'] ?? 'Instructor'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                course['description'] ?? 'No description available',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildProgressIndicator(courseId)),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course['totalLessons'] ?? 0} lessons',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String courseId) {
    return FutureBuilder<double>(
      future: _getCourseProgress(courseId),
      builder: (context, snapshot) {
        double progress = snapshot.data ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<double> _getCourseProgress(String courseId) async {
    try {
      // Get student's course progress
      DocumentSnapshot progressDoc =
          await _firestore
              .collection('course_progress')
              .doc('${_auth.currentUser?.uid}_$courseId')
              .get();

      if (progressDoc.exists) {
        Map<String, dynamic> data = progressDoc.data() as Map<String, dynamic>;
        List<dynamic> completedLessons = data['completedLessons'] ?? [];

        // Get total lessons in course
        DocumentSnapshot courseDoc =
            await _firestore.collection('courses').doc(courseId).get();

        if (courseDoc.exists) {
          Map<String, dynamic> courseData =
              courseDoc.data() as Map<String, dynamic>;
          int totalLessons = courseData['totalLessons'] ?? 1;

          return completedLessons.length / totalLessons;
        }
      }

      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void _navigateToCourseDetails(String courseId, Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CourseDetailsPage(courseId: courseId, course: course),
      ),
    );
  }

  void _showEnrollDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enroll in Course'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Browse available courses and enroll to start learning!',
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('courses').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    return SizedBox(
                      height: 200,
                      width: double.maxFinite,
                      child: ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = snapshot.data!.docs[index];
                          Map<String, dynamic> course =
                              doc.data() as Map<String, dynamic>;

                          return ListTile(
                            title: Text(course['title'] ?? 'Course'),
                            subtitle: Text(
                              course['instructor'] ?? 'Instructor',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                _enrollInCourse(doc.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Enroll'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _enrollInCourse(String courseId) async {
    try {
      await _firestore
          .collection('students')
          .doc(_auth.currentUser?.uid)
          .update({
            'coursesEnrolled': FieldValue.arrayUnion([courseId]),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully enrolled in course!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enrolling: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CourseDetailsPage extends StatelessWidget {
  final String courseId;
  final Map<String, dynamic> course;

  const CourseDetailsPage({
    Key? key,
    required this.courseId,
    required this.course,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(course['title'] ?? 'Course')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'] ?? 'Course Title',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instructor: ${course['instructor'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Course Description
            const Text(
              'About this course',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              course['description'] ?? 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Course Materials
            const Text(
              'Course Materials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCourseMaterials(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseMaterials() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('course_materials')
              .where('courseId', isEqualTo: courseId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No materials available yet'),
            ),
          );
        }

        return Column(
          children:
              snapshot.data!.docs.map((doc) {
                Map<String, dynamic> material =
                    doc.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      _getMaterialIcon(material['type']),
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(material['title'] ?? 'Material'),
                    subtitle: Text(material['description'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        // TODO: Implement download/view functionality
                      },
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  IconData _getMaterialIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'video':
        return Icons.play_circle;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.file_present;
    }
  }
}
