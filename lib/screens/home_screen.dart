import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Report> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshReports();
  }

  Future<void> _refreshReports() async {
    final data = await DatabaseHelper.instance.getAllReports();
    setState(() {
      _reports = data;
      _isLoading = false;
    });
  }

  // fake report for testing
  Future<void> _addDummyReport() async {
    final dummyReport = Report(
      imagePath: 'dummy_image_path.jpg', // will be replaced with real camera data later
      caption: 'Parkir sembarangan di TC!',
      latitude: -7.2823, // dummy coords
      longitude: 112.7949,
      timestamp: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertReport(dummyReport);
    _refreshReports();
  }

  Future<void> _deleteReport(int id) async {
    await DatabaseHelper.instance.deleteReport(id);
    _refreshReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parkir ITS - Local DB Test'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(child: Text('Belum ada laporan parkir.'))
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: const Icon(Icons.image, size: 50, color: Colors.grey),
                        title: Text(report.caption),
                        subtitle: Text('Lat: ${report.latitude}\nLon: ${report.longitude}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteReport(report.id!),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDummyReport,
        label: const Text('Add Dummy Data'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}