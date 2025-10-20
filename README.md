# LearnSphere - Educational Learning Management System

LearnSphere is a comprehensive educational platform built with Flutter and Firebase that provides separate dashboards for students and teachers with complete learning management features.

## 🌟 Features

### 🎓 Student Features
- **Authentication & Registration**: Secure login/registration with Firebase Auth
- **Dashboard**: Academic performance overview, upcoming assignments, quiz results
- **My Courses**: Browse and enroll in courses, track progress, access materials
- **Take Quiz**: Timer-based quizzes with random questions and instant scoring
- **Profile Management**: Edit profile, view statistics and achievements
- **Leaderboard**: Real-time rankings (overall, monthly, weekly)
- **Notifications**: Real-time alerts for assignments and announcements

### 👨‍🏫 Teacher Features
- **Teacher Dashboard**: Overview of classes, students, and assignments
- **Attendance Management**: Record and track student attendance
- **Announcements**: Create and manage class announcements
- **Class Management**: Create and manage classes, assign students
- **Student Information**: View and manage student data and performance
- **Quiz Creation**: Create quizzes with multiple choice questions
- **Assignment Management**: Create and grade assignments
- **Performance Analytics**: View student progress and statistics

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
2. **Firebase Project**: Create a project at [Firebase Console](https://console.firebase.google.com/)
3. **Firebase CLI**: [Install Firebase CLI](https://firebase.google.com/docs/cli)

### Firebase Setup

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Authentication, Firestore Database, and Storage

2. **Configure Authentication**:
   - Go to Authentication > Sign-in method
   - Enable Email/Password authentication

3. **Setup Firestore Database**:
   - Go to Firestore Database
   - Create database in production mode

### Installation

1. **Clone the repository**:
```bash
git clone <repository-url>
cd learnsphere
```

2. **Install dependencies**:
```bash
flutter pub get
```

3. **Run the app**:
```bash
flutter run
```

## 📱 Usage

### For Students

1. **Registration**: 
   - Open the app and tap "Sign Up"
   - Select "Student" role
   - Fill in details including Student ID
   - Create account

2. **Dashboard**:
   - View academic performance and statistics
   - See upcoming assignments and recent quiz results
   - Access enrolled courses quickly

3. **Courses**:
   - Browse available courses
   - Enroll in courses using the + button
   - Track progress and access materials

4. **Quizzes**:
   - Take timer-based quizzes
   - View instant results and scoring
   - Track quiz history and performance

### For Teachers

1. **Registration**:
   - Select "Teacher" role during registration
   - Provide Teacher ID

2. **Dashboard**:
   - Overview of classes and students
   - Quick actions for creating content
   - Recent activity monitoring

## 🛠 Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Free Tier)
  - **Authentication**: Firebase Auth
  - **Database**: Cloud Firestore
  - **Storage**: Firebase Storage
  - **Messaging**: Firebase Cloud Messaging
- **State Management**: Provider
- **UI**: Material Design

## 🚦 Firebase Free Tier

This app is designed to work within Firebase's free tier:
- **Firestore**: 50,000 reads, 20,000 writes, 20,000 deletes per day
- **Authentication**: Unlimited users
- **Storage**: 5GB total, 1GB/day downloads
- **Cloud Messaging**: Unlimited messages

## 📝 Key Components

### Student Module
- Dashboard with performance overview
- Course enrollment and progress tracking
- Interactive quiz system with timer
- Real-time leaderboard
- Profile management with statistics

### Teacher Module  
- Class and student management
- Quiz and assignment creation
- Attendance tracking
- Announcement system
- Performance analytics

## 🔧 Setup Instructions

1. Create Firebase project and enable required services
2. Add Firebase configuration files to your Flutter project
3. Install dependencies with `flutter pub get`
4. Run the app with `flutter run`

For detailed setup instructions, refer to the documentation.

---

**LearnSphere** - Empowering education through technology! 🚀📚
