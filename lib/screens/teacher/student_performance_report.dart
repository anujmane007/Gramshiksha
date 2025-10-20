import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StudentPerformanceScreen extends StatefulWidget {
  const StudentPerformanceScreen({super.key});

  @override
  State<StudentPerformanceScreen> createState() =>
      _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref("classes");
  final TextEditingController _studentIdController = TextEditingController();

  List<_ScoreData> _scores = [];
  bool _loading = false;
  String? _currentStudentId;
  String? _errorMessage;

  Future<void> _fetchScores(String studentId) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _currentStudentId = studentId;
    });

    try {
      List<_ScoreData> tempScores = [];

      // ✅ Fetch subject-wise data (classes → subjects → students)
      final snapshot = await _db.get();
      if (snapshot.exists) {
        for (var classNode in snapshot.children) {
          if (classNode.child("students").hasChild(studentId)) {
            final studentData = classNode.child("students").child(studentId);

            final subject =
                studentData.child("subject").value?.toString() ??
                "Unknown Subject";
            final score =
                double.tryParse(studentData.child("score").value.toString()) ??
                0;

            tempScores.add(_ScoreData(subject, score));
          }
        }
      }

      // ✅ If no subject-wise data is found, try direct student collection
      if (tempScores.isEmpty) {
        final studentSnap =
            await FirebaseDatabase.instance.ref("students/$studentId").get();
        if (studentSnap.exists) {
          final data = studentSnap.value as Map;

          if (data.containsKey("totalScore")) {
            tempScores.add(
              _ScoreData(
                "Overall Score",
                double.tryParse(data["totalScore"].toString()) ?? 0,
              ),
            );
          }
        }
      }

      setState(() {
        _scores = tempScores;
        _loading = false;
        if (_scores.isEmpty)
          _errorMessage = "No scores found for ID $studentId.";
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = "Error fetching: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Performance")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔎 Student ID Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: "Enter Student ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final id = _studentIdController.text.trim();
                    if (id.isNotEmpty) _fetchScores(id);
                  },
                  child: const Text("Search"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 📊 Chart Display
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(child: Center(child: Text(_errorMessage!)))
            else if (_scores.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 300, child: _buildPieChart()),
                      const SizedBox(height: 20),
                      SizedBox(height: 300, child: _buildBarChart()),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return SfCircularChart(
      title: ChartTitle(text: "Score Distribution for $_currentStudentId"),
      legend: Legend(isVisible: true),
      series: <CircularSeries>[
        PieSeries<_ScoreData, String>(
          dataSource: _scores,
          xValueMapper: (_ScoreData data, _) => data.subject,
          yValueMapper: (_ScoreData data, _) => data.score,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    return SfCartesianChart(
      title: ChartTitle(text: "Subject-wise Score"),
      primaryXAxis: CategoryAxis(),
      series: <CartesianSeries<_ScoreData, String>>[
        ColumnSeries<_ScoreData, String>(
          dataSource: _scores,
          xValueMapper: (_ScoreData data, _) => data.subject,
          yValueMapper: (_ScoreData data, _) => data.score,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class _ScoreData {
  final String subject;
  final double score;
  _ScoreData(this.subject, this.score);
}
