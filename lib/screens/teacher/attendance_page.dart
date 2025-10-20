import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedClassId;
  DateTime selectedDate = DateTime.now();
  Map<String, bool> attendanceStatus = {};
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTodaysAttendance();
  }

  Future<void> _loadTodaysAttendance() async {
    if (selectedClassId == null) return;

    setState(() => _isLoading = true);

    try {
      String dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

      DocumentSnapshot attendanceDoc =
          await _firestore
              .collection('attendance')
              .doc('${selectedClassId}_$dateString')
              .get();

      if (attendanceDoc.exists) {
        Map<String, dynamic> data =
            attendanceDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> attendance = data['attendance'] ?? {};

        setState(() {
          attendanceStatus = attendance.map(
            (key, value) => MapEntry(key, value as bool),
          );
        });
      } else {
        // Initialize attendance for all students as absent
        DocumentSnapshot classDoc =
            await _firestore.collection('classes').doc(selectedClassId).get();

        if (classDoc.exists) {
          Map<String, dynamic> classData =
              classDoc.data() as Map<String, dynamic>;
          List<dynamic> students = classData['students'] ?? [];

          setState(() {
            attendanceStatus = {
              for (String studentId in students.cast<String>())
                studentId: false,
            };
          });
        }
      }
    } catch (e) {
      print('Error loading attendance: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveAttendance() async {
    if (selectedClassId == null || attendanceStatus.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      String dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

      await _firestore
          .collection('attendance')
          .doc('${selectedClassId}_$dateString')
          .set({
            'classId': selectedClassId,
            'date': dateString,
            'attendance': attendanceStatus,
            'teacherId': _auth.currentUser!.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadTodaysAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date and Class Selection
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Date Display
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Class Selection
                StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestore
                          .collection('classes')
                          .where('teacherId', isEqualTo: _auth.currentUser!.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    List<DropdownMenuItem<String>> items =
                        snapshot.data!.docs.map((doc) {
                          Map<String, dynamic> classData =
                              doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(
                              classData['className'] ?? 'Unnamed Class',
                            ),
                          );
                        }).toList();

                    return DropdownButtonFormField<String>(
                      value: selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: items,
                      onChanged: (value) {
                        setState(() {
                          selectedClassId = value;
                          attendanceStatus.clear();
                        });
                        _loadTodaysAttendance();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Attendance List
          Expanded(
            child:
                selectedClassId == null
                    ? const Center(
                      child: Text(
                        'Please select a class to take attendance',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<DocumentSnapshot>(
                      stream:
                          _firestore
                              .collection('classes')
                              .doc(selectedClassId)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Center(child: Text('Class not found'));
                        }

                        Map<String, dynamic> classData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        List<dynamic> studentIds = classData['students'] ?? [];

                        if (studentIds.isEmpty) {
                          return const Center(
                            child: Text('No students enrolled in this class'),
                          );
                        }

                        return Column(
                          children: [
                            // Attendance Summary
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryItem(
                                    'Total',
                                    '${studentIds.length}',
                                    Colors.blue,
                                  ),
                                  _buildSummaryItem(
                                    'Present',
                                    '${attendanceStatus.values.where((present) => present).length}',
                                    Colors.green,
                                  ),
                                  _buildSummaryItem(
                                    'Absent',
                                    '${attendanceStatus.values.where((present) => !present).length}',
                                    Colors.red,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Students List
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: studentIds.length,
                                itemBuilder: (context, index) {
                                  String studentId = studentIds[index];

                                  return FutureBuilder<DocumentSnapshot>(
                                    future:
                                        _firestore
                                            .collection('users')
                                            .doc(studentId)
                                            .get(),
                                    builder: (context, userSnapshot) {
                                      if (!userSnapshot.hasData) {
                                        return const Card(
                                          child: ListTile(
                                            title: Text('Loading...'),
                                          ),
                                        );
                                      }

                                      Map<String, dynamic>? userData;
                                      if (userSnapshot.data!.exists) {
                                        userData =
                                            userSnapshot.data!.data()
                                                as Map<String, dynamic>;
                                      }

                                      bool isPresent =
                                          attendanceStatus[studentId] ?? false;

                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                isPresent
                                                    ? Colors.green
                                                    : Colors.red,
                                            child: Text(
                                              (userData?['fullName'] ?? 'S')
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            userData?['fullName'] ??
                                                'Unknown Student',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            userData?['studentId'] ?? 'No ID',
                                          ),
                                          trailing: Switch(
                                            value: isPresent,
                                            onChanged: (value) {
                                              setState(() {
                                                attendanceStatus[studentId] =
                                                    value;
                                              });
                                            },
                                            activeColor: Colors.green,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),

          // Save Button
          if (selectedClassId != null && attendanceStatus.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAttendance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Save Attendance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
