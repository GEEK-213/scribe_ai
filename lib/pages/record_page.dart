import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
import '../theme/app_theme.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordedFilePath;
  Stopwatch _stopwatch = Stopwatch();
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
    _timer?.cancel(); // Pause timer visually
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });
    
    // Auto-upload logic (kept simple for UI demo)
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

      await Supabase.instance.client.storage.from('lectures').upload(fileName, file);

      await Supabase.instance.client.from('notes').insert({
        'title': 'Lecture ${DateTime.now().hour}:${DateTime.now().minute}',
        'audio_path': fileName,
        'status': 'Processing',
        'user_id': userId,
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
            // 1. STATUS CARD
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

            // 2. GIANT TIMER
            Text(
              _formattedTime,
              style: const TextStyle(
                fontSize: 60, 
                fontWeight: FontWeight.w200, 
                color: AppTheme.deepBlue,
                fontFeatures: [FontFeature.tabularFigures()], // Keeps numbers steady
              ),
            ),

            const SizedBox(height: 80),

            // 3. THE BIG BUTTON
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