import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _setup();
  }

  Future<void> _setup() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final file = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Camera error: ${snapshot.error}'));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: FloatingActionButton(
                    onPressed: _takePhoto,
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
