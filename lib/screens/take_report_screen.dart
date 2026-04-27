import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/report_model.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

class TakeReportScreen extends StatefulWidget {
  const TakeReportScreen({super.key});

  @override
  State<TakeReportScreen> createState() => _TakeReportScreenState();
}

class _TakeReportScreenState extends State<TakeReportScreen> {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  File? _capturedImage;
  double? _latitude;
  double? _longitude;
  final TextEditingController _captionController = TextEditingController();
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  bool _isGettingLocation = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera available')));
      return;
    }
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    try {
      await _controller!.initialize();
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera initialization failed: $e')));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;
    setState(() => _isTakingPicture = true);
    try {
      final XFile photo = await _controller!.takePicture();
      final Directory docDir = await getApplicationDocumentsDirectory();
      final String uniqueFileName = 'parking_report_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File permanentImage = File(p.join(docDir.path, uniqueFileName));
      await File(photo.path).copy(permanentImage.path);
      setState(() {
        _capturedImage = permanentImage;
        _isTakingPicture = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
      setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
        setState(() => _isGettingLocation = false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied. Enable in settings.')));
       setState(() => _isGettingLocation = false);
       return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveReport() async {
    if (_capturedImage == null || _latitude == null || _longitude == null || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please take photo, get location, and add caption')));
      return;
    }
    setState(() => _isSaving = true);
    final report = Report(
      imagePath: _capturedImage!.path,
      caption: _captionController.text,
      latitude: _latitude!,
      longitude: _longitude!,
      timestamp: DateTime.now().toIso8601String(),
    );
    try {
      await DatabaseHelper.instance.insertReport(report);
      SyncService().pushLocalReportsToCloud();
      if(mounted) Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving report: $e')));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Report'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _capturedImage == null
                ? (_isCameraInitialized
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: CameraPreview(_controller!),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _isTakingPicture
                                ? const CircularProgressIndicator()
                                : FloatingActionButton(
                                    onPressed: _takePicture,
                                    child: const Icon(Icons.camera),
                                  ),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()))
                : Column(
                    children: [
                      Image.file(_capturedImage!, height: 300),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => setState(() => _capturedImage = null),
                            child: const Text('Retake'),
                          ),
                          ElevatedButton(
                            onPressed: _getLocation,
                            child: _isGettingLocation
                                ? const CircularProgressIndicator()
                                : Text(_latitude == null ? 'Get Location' : 'Refresh Loc'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_latitude != null && _longitude != null)
                        Text('Lat: $_latitude\nLon: $_longitude', textAlign: TextAlign.center),
                    ],
                  ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Caption (e.g., Lokasi parkir)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSaving)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _saveReport,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Report', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}