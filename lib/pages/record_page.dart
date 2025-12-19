import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
import '../theme/app_theme.dart';

class RecordPage extends StatefulWidget {
  // 1. Accept folderId (Optional, can be null for Root)
  final int? folderId; 
  
  const RecordPage({super.key, this.folderId});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordedFilePath;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = "00:00:00";

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final duration = _stopwatch.elapsed;
        _formattedTime = 
            "${duration.inHours.toString().padLeft(2, '0')}:"
            "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
            "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
      });
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _stopwatch.reset();
    _timer?.cancel();
    setState(() => _formattedTime = "00:00:00");
  }

  Future<void> _record() async {
    if (!_isRecorderInitialized) return;
    await _recorder.startRecorder(toFile: 'temp_audio.aac');
    _startTimer();
    setState(() => _isRecording = true);
  }

  Future<void> _stop() async {
    if (!_isRecorderInitialized) return;
    final path = await _recorder.stopRecorder();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });
    
    // Auto-upload
    if (_recordedFilePath != null) {
      _uploadRecording(File(_recordedFilePath!));
    }
  }

  Future<void> _uploadRecording(File file) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving Lecture...')));
    
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_rec.aac';
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Upload File to Bucket
      try {
         await Supabase.instance.client.storage.from('Lectures').upload(fileName, file);
      } catch (e) {
         // Fallback for capitalized bucket name
         await Supabase.instance.client.storage.from('Lectures').upload(fileName, file);
      }

      // 2. Save Metadata to Database (Now with Folder ID!)
      await Supabase.instance.client.from('notes').insert({
        'title': 'Lecture ${DateTime.now().hour}:${DateTime.now().minute}',
        'audio_path': fileName,
        'status': 'Processing',
        'user_id': userId,
        'folder_id': widget.folderId, // <--- SAVING TO FOLDER
      });

      if (mounted) {
        Navigator.pop(context); // Go back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lecture Saved!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Recording Studio"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.deepBlue),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isRecording ? Icons.fiber_manual_record : Icons.mic_none, 
                       color: _isRecording ? Colors.red : AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(_isRecording ? "Recording in progress..." : "Ready to capture",
                       style: TextStyle(color: _isRecording ? Colors.red : AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const SizedBox(height: 50),

            // Timer
            Text(
              _formattedTime,
              style: const TextStyle(
                fontSize: 60, 
                fontWeight: FontWeight.w200, 
                color: AppTheme.deepBlue,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),

            const SizedBox(height: 80),

            // Record Button
            GestureDetector(
              onTap: _isRecording ? _stop : _record,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isRecording ? 100 : 120,
                width: _isRecording ? 100 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.redAccent : AppTheme.primaryBlue,
                  boxShadow: [
                    BoxShadow(
                      color: _isRecording ? Colors.red.withOpacity(0.4) : Colors.blue.withOpacity(0.4),
                      blurRadius: _isRecording ? 20 : 10,
                      spreadRadius: _isRecording ? 10 : 2,
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic, 
                  size: 50, 
                  color: Colors.white
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            Text(
              _isRecording ? "Tap to Finish" : "Tap to Start",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}