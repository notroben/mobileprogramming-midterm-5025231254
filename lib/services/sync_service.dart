import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'database_helper.dart';
import 'notification_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> pushLocalReportsToCloud() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      String username = userDoc.exists ? userDoc['username'] : 'Anonim';

      final unsyncedReports = await DatabaseHelper.instance.getUnsyncedReports();

      for (var report in unsyncedReports) {
        try {
          File imageFile = File(report.imagePath);
          String fileName = 'reports/${currentUser.uid}_${report.timestamp}.jpg';
          
          TaskSnapshot snapshot = await _storage.ref(fileName).putFile(imageFile);
          String downloadUrl = await snapshot.ref.getDownloadURL();

          await _firestore.collection('public_reports').add({
            'reporterId': currentUser.uid,
            'reporterUsername': username,
            'imageUrl': downloadUrl,
            'caption': report.caption,
            'latitude': report.latitude,
            'longitude': report.longitude,
            'timestamp': report.timestamp, 
            'uploadedAt': FieldValue.serverTimestamp(),
          });

          await DatabaseHelper.instance.markAsSynced(report.id!);
          print("Successfully synced report: ${report.id}");
          
          await NotificationService().showNotification(
            id: report.id!, 
            title: 'Upload Berhasil!', 
            body: 'Laporan parkir kamu sudah masuk ke Forum Kampus.',
          );
        } catch (e) {
          print("Failed to sync individual report ${report.id}: $e");
        }
      }
    } catch (e) {
      print("Network error or Firestore unavailable. Sync aborted: $e");
    }
  }
}