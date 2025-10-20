import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../teacher/teacher_home_page.dart';
import '../teacher/attendance_page.dart';
import '../teacher/announcements_page.dart';
import '../teacher/class_management_page.dart';
import '../teacher/student_info_page.dart';
import '../teacher/teacher_profile_page.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    TeacherHomePage(
      onTabChange: (index) => setState(() => _selectedIndex = index),
    ),
    const AttendancePage(),
    const AnnouncementsPage(),
    const ClassManagementPage(),
    const StudentInfoPage(),
    const TeacherProfilePage(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Attendance'),
    BottomNavigationBarItem(
      icon: Icon(Icons.announcement),
      label: 'Announcements',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Classes'),
    BottomNavigationBarItem(icon: Icon(Icons.person_search), label: 'Students'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _bottomNavItems,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              accountName: Text(
                FirebaseAuth.instance.currentUser?.displayName ?? 'Teacher',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  FirebaseAuth.instance.currentUser?.displayName
                          ?.substring(0, 1)
                          .toUpperCase() ??
                      'T',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Attendance'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('Announcements'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('Class Management'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_search),
              title: const Text('Student Information'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Video Lectures'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to video lectures page
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Performance Analytics'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to analytics page
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 5);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Manage Quizzes'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to quiz management
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Assignments'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to assignment management
              },
            ),
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Grades'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to grades management
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings page
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                Navigator.pop(context);
                await Provider.of<AuthService>(
                  context,
                  listen: false,
                ).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
