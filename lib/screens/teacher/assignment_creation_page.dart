import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AssignmentCreationPage extends StatefulWidget {
  const AssignmentCreationPage({Key? key}) : super(key: key);

  @override
  State<AssignmentCreationPage> createState() => _AssignmentCreationPageState();
}

class _AssignmentCreationPageState extends State<AssignmentCreationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _pointsController = TextEditingController();

  String? _selectedClassId;
  DateTime? _dueDate;
  List<File> _attachedFiles = [];
  List<String> _uploadedFileUrls = [];
  bool _isCreating = false;
  bool _allowLateSubmission = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _attachedFiles.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  Future<void> _selectDueDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );

      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<String> _uploadFile(File file) async {
    String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    Reference ref = _storage.ref().child('assignments').child(fileName);

    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Upload files
      List<String> fileUrls = [];
      List<String> fileNames = [];

      for (File file in _attachedFiles) {
        String url = await _uploadFile(file);
        fileUrls.add(url);
        fileNames.add(file.path.split('/').last);
      }

      // Get class information
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(_selectedClassId).get();
      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

      await _firestore.collection('assignments').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'points': int.parse(_pointsController.text),
        'classId': _selectedClassId,
        'className': classData['className'],
        'teacherId': _auth.currentUser!.uid,
        'teacherName': _auth.currentUser?.displayName ?? 'Teacher',
        'dueDate': Timestamp.fromDate(_dueDate!),
        'allowLateSubmission': _allowLateSubmission,
        'attachments': fileUrls,
        'attachmentNames': fileNames,
        'submissions': [],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _instructionsController.clear();
      _pointsController.clear();
      setState(() {
        _selectedClassId = null;
        _dueDate = null;
        _attachedFiles.clear();
        _allowLateSubmission = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isCreating = false);
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assignment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assignment Details
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assignment Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _titleController,
                        label: 'Assignment Title',
                        prefixIcon: Icons.assignment,
                        validator:
                            (value) =>
                                value?.isEmpty == true
                                    ? 'Please enter title'
                                    : null,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        prefixIcon: Icons.description,
                        maxLines: 3,
                        validator:
                            (value) =>
                                value?.isEmpty == true
                                    ? 'Please enter description'
                                    : null,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _instructionsController,
                        label: 'Instructions',
                        prefixIcon: Icons.list,
                        maxLines: 4,
                        validator:
                            (value) =>
                                value?.isEmpty == true
                                    ? 'Please enter instructions'
                                    : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _pointsController,
                              label: 'Points',
                              prefixIcon: Icons.star,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty == true)
                                  return 'Please enter points';
                                if (int.tryParse(value!) == null)
                                  return 'Please enter valid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectDueDate,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _dueDate == null
                                            ? 'Select Due Date'
                                            : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color:
                                              _dueDate == null
                                                  ? Colors.grey
                                                  : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Class Selection
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            _firestore
                                .collection('classes')
                                .where(
                                  'teacherId',
                                  isEqualTo: _auth.currentUser!.uid,
                                )
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
                            value: _selectedClassId,
                            decoration: const InputDecoration(
                              labelText: 'Select Class',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.class_),
                            ),
                            items: items,
                            onChanged:
                                (value) =>
                                    setState(() => _selectedClassId = value),
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Please select a class'
                                        : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Late Submission Toggle
                      SwitchListTile(
                        title: const Text('Allow Late Submission'),
                        subtitle: const Text(
                          'Students can submit after due date',
                        ),
                        value: _allowLateSubmission,
                        onChanged: (value) {
                          setState(() {
                            _allowLateSubmission = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Attachments Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Add Files'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_attachedFiles.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No files attached',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Supported: PDF, DOC, DOCX, TXT, JPG, PNG',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: List.generate(_attachedFiles.length, (
                            index,
                          ) {
                            File file = _attachedFiles[index];
                            String fileName = file.path.split('/').last;

                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.attach_file),
                                title: Text(fileName),
                                subtitle: Text(
                                  '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeFile(index),
                                ),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: _isCreating ? null : _createAssignment,
                  isLoading: _isCreating,
                  child: const Text(
                    'Create Assignment',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
