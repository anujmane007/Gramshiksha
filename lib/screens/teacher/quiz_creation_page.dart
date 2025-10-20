import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class QuizCreationPage extends StatefulWidget {
  const QuizCreationPage({Key? key}) : super(key: key);

  @override
  State<QuizCreationPage> createState() => _QuizCreationPageState();
}

class _QuizCreationPageState extends State<QuizCreationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  String? _selectedClassId;
  List<Map<String, dynamic>> _questions = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'questionText': '',
        'options': ['', '', '', ''],
        'correctAnswer': 0,
        'points': 1,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _createQuiz() async {
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
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i]['questionText'].trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1} text cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      for (int j = 0; j < 4; j++) {
        if (_questions[i]['options'][j].trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Question ${i + 1}, Option ${j + 1} cannot be empty',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isCreating = true);

    try {
      // Get students from the selected class
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(_selectedClassId).get();
      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

      await _firestore.collection('quizzes').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'duration': int.parse(_durationController.text),
        'classId': _selectedClassId,
        'className': classData['className'],
        'teacherId': _auth.currentUser!.uid,
        'teacherName': _auth.currentUser?.displayName ?? 'Teacher',
        'questions': _questions,
        'totalQuestions': _questions.length,
        'totalPoints': _questions.fold<int>(
          0,
          (sum, q) => sum + (q['points'] as int),
        ),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _durationController.clear();
      setState(() {
        _questions.clear();
        _selectedClassId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating quiz: $e'),
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
        title: const Text('Create Quiz'),
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
              // Quiz Details Section
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
                        'Quiz Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _titleController,
                        label: 'Quiz Title',
                        prefixIcon: Icons.quiz,
                        validator:
                            (value) =>
                                value?.isEmpty == true
                                    ? 'Please enter quiz title'
                                    : null,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description (Optional)',
                        prefixIcon: Icons.description,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _durationController,
                        label: 'Duration (minutes)',
                        prefixIcon: Icons.timer,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true)
                            return 'Please enter duration';
                          if (int.tryParse(value!) == null)
                            return 'Please enter valid number';
                          return null;
                        },
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Questions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Questions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Questions List
              if (_questions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No questions added yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click "Add Question" to get started',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(
                  _questions.length,
                  (index) => _buildQuestionCard(index),
                ),

              const SizedBox(height: 30),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: _isCreating ? null : _createQuiz,
                  isLoading: _isCreating,
                  child: const Text(
                    'Create Quiz',
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

  Widget _buildQuestionCard(int questionIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question ${questionIndex + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeQuestion(questionIndex),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Text
            TextFormField(
              initialValue: _questions[questionIndex]['questionText'],
              decoration: const InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
              ),
              maxLines: 2,
              onChanged:
                  (value) => _questions[questionIndex]['questionText'] = value,
            ),
            const SizedBox(height: 16),

            // Options
            const Text(
              'Options:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            ...List.generate(4, (optionIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: optionIndex,
                      groupValue: _questions[questionIndex]['correctAnswer'],
                      onChanged: (value) {
                        setState(() {
                          _questions[questionIndex]['correctAnswer'] = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue:
                            _questions[questionIndex]['options'][optionIndex],
                        decoration: InputDecoration(
                          labelText:
                              'Option ${String.fromCharCode(65 + optionIndex)}',
                          border: const OutlineInputBorder(),
                          filled:
                              _questions[questionIndex]['correctAnswer'] ==
                              optionIndex,
                          fillColor:
                              _questions[questionIndex]['correctAnswer'] ==
                                      optionIndex
                                  ? Colors.green.withOpacity(0.1)
                                  : null,
                        ),
                        onChanged: (value) {
                          _questions[questionIndex]['options'][optionIndex] =
                              value;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Points
            Row(
              children: [
                const Text(
                  'Points: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue:
                        _questions[questionIndex]['points'].toString(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _questions[questionIndex]['points'] =
                          int.tryParse(value) ?? 1;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
