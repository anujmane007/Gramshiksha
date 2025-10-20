import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sample data for testing
  static Future<void> seedSampleData() async {
    try {
      await _seedCourses();
      await _seedQuizzes();
      await _seedAnnouncements();
      await _seedAssignments();
      print('Sample data seeded successfully!');
    } catch (e) {
      print('Error seeding data: $e');
    }
  }

  static Future<void> _seedCourses() async {
    List<Map<String, dynamic>> courses = [
      {
        'title': 'Introduction to Computer Science',
        'description': 'Learn the fundamentals of computer science including programming, algorithms, and data structures.',
        'instructor': 'Dr. John Smith',
        'teacherId': 'teacher_sample_id',
        'totalLessons': 15,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Mathematics for Engineers',
        'description': 'Advanced mathematics concepts essential for engineering students.',
        'instructor': 'Prof. Sarah Johnson',
        'teacherId': 'teacher_sample_id_2',
        'totalLessons': 20,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Digital Marketing Fundamentals',
        'description': 'Learn the basics of digital marketing including SEO, social media, and content marketing.',
        'instructor': 'Ms. Emily Davis',
        'teacherId': 'teacher_sample_id_3',
        'totalLessons': 12,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Data Science with Python',
        'description': 'Comprehensive course on data science using Python and popular libraries.',
        'instructor': 'Dr. Michael Chen',
        'teacherId': 'teacher_sample_id_4',
        'totalLessons': 25,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
    ];

    for (var course in courses) {
      await _firestore.collection('courses').add(course);
    }
  }

  static Future<void> _seedQuizzes() async {
    // First, create a quiz
    DocumentReference quizRef = await _firestore.collection('quizzes').add({
      'title': 'Programming Fundamentals Quiz',
      'description': 'Test your knowledge of basic programming concepts',
      'subject': 'Computer Science',
      'duration': 30,
      'totalQuestions': 5,
      'maxScore': 50,
      'teacherId': 'teacher_sample_id',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    // Add questions for the quiz
    List<Map<String, dynamic>> questions = [
      {
        'quizId': quizRef.id,
        'question': 'What is a variable in programming?',
        'options': [
          'A storage location with an associated name',
          'A type of loop',
          'A function',
          'An operator'
        ],
        'correctAnswer': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'quizId': quizRef.id,
        'question': 'Which of the following is NOT a programming language?',
        'options': [
          'Python',
          'Java',
          'HTML',
          'C++'
        ],
        'correctAnswer': 2,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'quizId': quizRef.id,
        'question': 'What does IDE stand for?',
        'options': [
          'Internet Development Environment',
          'Integrated Development Environment',
          'Interactive Design Environment',
          'Internal Database Engine'
        ],
        'correctAnswer': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'quizId': quizRef.id,
        'question': 'What is the purpose of a loop in programming?',
        'options': [
          'To store data',
          'To repeat a block of code',
          'To define a function',
          'To create variables'
        ],
        'correctAnswer': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'quizId': quizRef.id,
        'question': 'Which symbol is commonly used for comments in many programming languages?',
        'options': [
          '#',
          '//',
          '/*',
          'All of the above'
        ],
        'correctAnswer': 3,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var question in questions) {
      await _firestore.collection('quiz_questions').add(question);
    }

    // Create another quiz for Mathematics
    DocumentReference mathQuizRef = await _firestore.collection('quizzes').add({
      'title': 'Basic Algebra Quiz',
      'description': 'Test your algebra skills',
      'subject': 'Mathematics',
      'duration': 25,
      'totalQuestions': 4,
      'maxScore': 40,
      'teacherId': 'teacher_sample_id_2',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    List<Map<String, dynamic>> mathQuestions = [
      {
        'quizId': mathQuizRef.id,
        'question': 'What is the value of x in the equation: 2x + 5 = 15?',
        'options': ['5', '10', '7.5', '3'],
        'correctAnswer': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'quizId': mathQuizRef.id,
        'question': 'Simplify: 3(x + 2) - 2x',
        'options': ['x + 6', 'x + 2', '3x + 6', '5x + 6'],
        'correctAnswer': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'quizId': mathQuizRef.id,
        'question': 'What is the slope of the line y = 2x + 3?',
        'options': ['2', '3', '2x', '5'],
        'correctAnswer': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'quizId': mathQuizRef.id,
        'question': 'Factor: x² - 4',
        'options': ['(x-2)(x-2)', '(x+2)(x+2)', '(x+2)(x-2)', 'Cannot be factored'],
        'correctAnswer': 2,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var question in mathQuestions) {
      await _firestore.collection('quiz_questions').add(question);
    }
  }

  static Future<void> _seedAnnouncements() async {
    List<Map<String, dynamic>> announcements = [
      {
        'title': 'Welcome to the New Semester!',
        'content': 'Welcome back students! We hope you have a great semester. Please check your course schedules and make sure to attend the orientation session.',
        'teacherId': 'teacher_sample_id',
        'targetAudience': 'all',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Assignment Submission Deadline Extended',
        'content': 'The deadline for the Computer Science assignment has been extended to next Friday. Please make sure to submit your work on time.',
        'teacherId': 'teacher_sample_id',
        'targetAudience': 'cs_students',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Mathematics Extra Study Session',
        'content': 'There will be an extra study session for the upcoming mathematics exam this Saturday at 2 PM in Room 301.',
        'teacherId': 'teacher_sample_id_2',
        'targetAudience': 'math_students',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Library Hours Extended',
        'content': 'Great news! The library will now be open until 10 PM on weekdays to help you with your studies.',
        'teacherId': 'admin',
        'targetAudience': 'all',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
    ];

    for (var announcement in announcements) {
      await _firestore.collection('announcements').add(announcement);
    }
  }

  static Future<void> _seedAssignments() async {
    List<Map<String, dynamic>> assignments = [
      {
        'title': 'Programming Project - Calculator App',
        'description': 'Create a simple calculator application using your preferred programming language. The calculator should support basic arithmetic operations.',
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        'teacherId': 'teacher_sample_id',
        'courseId': 'course_cs_101',
        'maxScore': 100,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Algebra Problem Set',
        'description': 'Complete problems 1-25 from Chapter 3 of your textbook. Show all work and solve for all variables.',
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'teacherId': 'teacher_sample_id_2',
        'courseId': 'course_math_201',
        'maxScore': 50,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Market Research Report',
        'description': 'Conduct market research on a product of your choice and prepare a comprehensive report including target audience analysis, competitor research, and marketing strategies.',
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 21))),
        'teacherId': 'teacher_sample_id_3',
        'courseId': 'course_marketing_101',
        'maxScore': 150,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
      {
        'title': 'Data Analysis with Python',
        'description': 'Analyze the provided dataset using Python and pandas. Create visualizations and provide insights about the data trends.',
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 10))),
        'teacherId': 'teacher_sample_id_4',
        'courseId': 'course_datascience_301',
        'maxScore': 120,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      },
    ];

    for (var assignment in assignments) {
      await _firestore.collection('assignments').add(assignment);
    }
  }

  // Seed course materials
  static Future<void> seedCourseMaterials() async {
    List<Map<String, dynamic>> materials = [
      {
        'courseId': 'course_cs_101',
        'title': 'Introduction to Programming - Lecture 1',
        'description': 'Basic concepts of programming and computer science',
        'type': 'video',
        'url': 'https://example.com/video1.mp4',
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': 'teacher_sample_id',
      },
      {
        'courseId': 'course_cs_101', 
        'title': 'Programming Fundamentals PDF',
        'description': 'Comprehensive guide to programming fundamentals',
        'type': 'pdf',
        'url': 'https://example.com/programming_guide.pdf',
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': 'teacher_sample_id',
      },
      {
        'courseId': 'course_math_201',
        'title': 'Algebra Formulas Reference Sheet',
        'description': 'Quick reference for all important algebra formulas',
        'type': 'document',
        'url': 'https://example.com/algebra_formulas.doc',
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': 'teacher_sample_id_2',
      },
    ];

    for (var material in materials) {
      await _firestore.collection('course_materials').add(material);
    }
  }
}