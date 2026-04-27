import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'take_report_screen.dart';
import 'login_screen.dart';
import 'forum_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();

  int _selectedIndex = 0;
  
  List<Report> _localReports = [];
  bool _isLoadingLocal = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _refreshLocalReports();
  }

  Future<void> _refreshLocalReports() async {
    final data = await DatabaseHelper.instance.getAllReports();
    setState(() {
      _localReports = data;
      _isLoadingLocal = false;
    });
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    
    await _syncService.pushLocalReportsToCloud();
    
    setState(() => _isSyncing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sinkronisasi ke Cloud selesai!')),
      );
    }
    _refreshLocalReports();
  }

  Future<void> _handleLogout() async {
    await DatabaseHelper.instance.clearAllReports(); 
    
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Profil Pengguna'),
          ],
        ),
        content: const Text('Apakah Anda ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    if (_selectedIndex == 0) {
      currentBody = const ForumFeedScreen();
    } else {
      currentBody = _buildLocalList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Forum Parkir ITS' : 'Laporan Saya'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedIndex == 1) // Only show sync button on the local list page
            _isSyncing 
              ? const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))))
              : IconButton(icon: const Icon(Icons.cloud_upload), onPressed: _handleSync),
          IconButton(icon: const Icon(Icons.account_circle), onPressed: _showProfileDialog),
        ],
      ),
      body: currentBody,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TakeReportScreen())).then((_) => _refreshLocalReports());
        },
        label: const Text('Lapor!'),
        icon: const Icon(Icons.add_a_photo),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }

  Widget _buildLocalList() {
    if (_isLoadingLocal) return const Center(child: CircularProgressIndicator());
    if (_localReports.isEmpty) return const Center(child: Text('Kamu belum membuat laporan.'));
    
    return ListView.builder(
      itemCount: _localReports.length,
      itemBuilder: (context, index) {
        final report = _localReports[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Image.file(File(report.imagePath), width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
            title: Text(report.caption),
            subtitle: Text('Status: ${report.isSynced == 1 ? "Tersinkronisasi ☁️" : "Lokal 📱"}'),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteReport(report.id!)),
          ),
        );
      },
    );
  }

  Future<void> _deleteReport(int id) async {
    await DatabaseHelper.instance.deleteReport(id);
    _refreshLocalReports();
  }
}