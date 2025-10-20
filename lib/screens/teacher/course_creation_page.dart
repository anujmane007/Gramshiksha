import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CourseCreationPage extends StatefulWidget {
  const CourseCreationPage({Key? key}) : super(key: key);

  @override
  State<CourseCreationPage> createState() => _CourseCreationPageState();
}

class _CourseCreationPageState extends State<CourseCreationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();

  String? _selectedLevel = 'Beginner';
  File? _thumbnailFile;
  String? _thumbnailUrl;
  List<Map<String, dynamic>> _modules = [];
  bool _isCreating = false;
  bool _isPublic = true;

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _thumbnailFile = File(result.files.single.path!);
      });
    }
  }

  Future<String> _uploadThumbnail() async {
    if (_thumbnailFile == null) return '';

    String fileName =
        'course_thumbnails/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child(fileName);

    UploadTask uploadTask = ref.putFile(_thumbnailFile!);
    TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  void _addModule() {
    showDialog(
      context: context,
      builder:
          (context) => _ModuleDialog(
            onAdd: (module) {
              setState(() {
                _modules.add(module);
              });
            },
          ),
    );
  }

  void _editModule(int index) {
    showDialog(
      context: context,
      builder:
          (context) => _ModuleDialog(
            module: _modules[index],
            onAdd: (module) {
              setState(() {
                _modules[index] = module;
              });
            },
          ),
    );
  }

  void _removeModule(int index) {
    setState(() {
      _modules.removeAt(index);
    });
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one module'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Upload thumbnail if selected
      if (_thumbnailFile != null) {
        _thumbnailUrl = await _uploadThumbnail();
      }

      // Create course document
      await _firestore.collection('courses').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'level': _selectedLevel,
        'duration': _durationController.text.trim(),
        'thumbnailUrl': _thumbnailUrl ?? '',
        'instructorId': _auth.currentUser!.uid,
        'instructorName': _auth.currentUser?.displayName ?? 'Instructor',
        'modules': _modules,
        'enrolledStudents': [],
        'isPublic': _isPublic,
        'isActive': true,
        'rating': 0.0,
        'totalRatings': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _categoryController.clear();
      _durationController.clear();
      setState(() {
        _selectedLevel = 'Beginner';
        _thumbnailFile = null;
        _thumbnailUrl = null;
        _modules.clear();
        _isPublic = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Course'),
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
              // Course Details Section
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
                        'Course Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _titleController,
                        label: 'Course Title',
                        prefixIcon: Icons.book,
                        validator:
                            (value) =>
                                value?.isEmpty == true
                                    ? 'Please enter course title'
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

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _categoryController,
                              label: 'Category',
                              prefixIcon: Icons.category,
                              validator:
                                  (value) =>
                                      value?.isEmpty == true
                                          ? 'Please enter category'
                                          : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _durationController,
                              label: 'Duration (e.g., 4 weeks)',
                              prefixIcon: Icons.schedule,
                              validator:
                                  (value) =>
                                      value?.isEmpty == true
                                          ? 'Please enter duration'
                                          : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Level Selection
                      DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: const InputDecoration(
                          labelText: 'Course Level',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.trending_up),
                        ),
                        items:
                            _levels
                                .map(
                                  (level) => DropdownMenuItem(
                                    value: level,
                                    child: Text(level),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => _selectedLevel = value),
                      ),
                      const SizedBox(height: 16),

                      // Thumbnail Section
                      const Text(
                        'Course Thumbnail',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: _pickThumbnail,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child:
                              _thumbnailFile != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _thumbnailFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add thumbnail',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Public/Private Toggle
                      SwitchListTile(
                        title: const Text('Make course public'),
                        subtitle: const Text(
                          'Students can discover and enroll in this course',
                        ),
                        value: _isPublic,
                        onChanged: (value) => setState(() => _isPublic = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Modules Section
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
                            'Course Modules',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addModule,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Module'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_modules.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.library_books_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No modules added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add modules to structure your course content',
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
                          children: List.generate(_modules.length, (index) {
                            var module = _modules[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(
                                  module['title'] ?? 'Untitled Module',
                                ),
                                subtitle: Text(
                                  module['description'] ?? 'No description',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editModule(index);
                                    } else if (value == 'delete') {
                                      _removeModule(index);
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
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
                  onPressed: _isCreating ? null : _createCourse,
                  isLoading: _isCreating,
                  child: const Text(
                    'Create Course',
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

class _ModuleDialog extends StatefulWidget {
  final Map<String, dynamic>? module;
  final Function(Map<String, dynamic>) onAdd;

  const _ModuleDialog({required this.onAdd, this.module});

  @override
  State<_ModuleDialog> createState() => _ModuleDialogState();
}

class _ModuleDialogState extends State<_ModuleDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.module?['title'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.module?['description'] ?? '',
    );
    _contentController = TextEditingController(
      text: widget.module?['content'] ?? '',
    );
    _durationController = TextEditingController(
      text: widget.module?['duration'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.module == null ? 'Add Module' : 'Edit Module'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Module Title',
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              prefixIcon: Icons.description,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _contentController,
              label: 'Content',
              prefixIcon: Icons.article,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _durationController,
              label: 'Duration (e.g., 2 hours)',
              prefixIcon: Icons.schedule,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter module title')),
              );
              return;
            }

            widget.onAdd({
              'title': _titleController.text.trim(),
              'description': _descriptionController.text.trim(),
              'content': _contentController.text.trim(),
              'duration': _durationController.text.trim(),
              'createdAt': DateTime.now().toIso8601String(),
            });

            Navigator.pop(context);
          },
          child: Text(widget.module == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
