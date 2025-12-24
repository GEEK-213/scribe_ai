import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class RecordPage extends StatefulWidget {
  final int? folderId; 
  
  const RecordPage({super.key, this.folderId});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordedFilePath;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = "00:00:00";
  
  // Animation for the pulsing ring
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
    _pulseController.dispose();
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

  Future<void> _record() async {
    if (!_isRecorderInitialized) return;
    await _recorder.startRecorder(toFile: 'temp_audio.aac');
    _startTimer();
    _pulseController.repeat(reverse: true); // Start pulsing
    setState(() => _isRecording = true);
  }

  Future<void> _stop() async {
    if (!_isRecorderInitialized) return;
    final path = await _recorder.stopRecorder();
    _timer?.cancel();
    _stopwatch.stop();
    _pulseController.stop();
    _pulseController.reset();
    
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });
    
    if (_recordedFilePath != null) {
      _uploadRecording(File(_recordedFilePath!));
    }
  }

  Future<void> _uploadRecording(File file) async {
    if (!mounted) return;
    
    // Show uploading glass dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppTheme.primaryBlue),
              SizedBox(height: 20),
              Text("Uploading & AI Processing...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_rec.aac';
      final userId = Supabase.instance.client.auth.currentUser!.id;

      try {
         await Supabase.instance.client.storage.from('Lectures').upload(fileName, file);
      } catch (e) {
         await Supabase.instance.client.storage.from('Lectures').upload(fileName, file);
      }

      await Supabase.instance.client.from('notes').insert({
        'title': 'Lecture ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'audio_path': fileName,
        'status': 'Processing',
        'user_id': userId,
        'folder_id': widget.folderId,
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Lumen Background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Recording Studio"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. AMBIENT GLOW
          Positioned(
            top: -100, right: -100,
            child: _buildOrb(400, const Color(0xFF2B8CEE).withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: _buildOrb(300, Colors.redAccent.withOpacity(0.1)),
          ),

          // 2. MAIN CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isRecording ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.redAccent : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: _isRecording ? [const BoxShadow(color: Colors.redAccent, blurRadius: 10)] : [],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording ? "ON AIR" : "STANDBY",
                        style: TextStyle(
                          color: _isRecording ? Colors.redAccent : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),

                // Digital Timer
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontSize: 72, 
                    fontWeight: FontWeight.w200, 
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()], // Keeps numbers width consistent
                    letterSpacing: -2,
                  ),
                ),

                const SizedBox(height: 80),

                // Record Button
                GestureDetector(
                  onTap: _isRecording ? _stop : _record,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 100, width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isRecording 
                              ? [const Color(0xFFFF4B4B), const Color(0xFFD32F2F)] 
                              : [const Color(0xFF2B8CEE), const Color(0xFF0D7FF2)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isRecording ? const Color(0xFFFF4B4B).withOpacity(0.6) : const Color(0xFF2B8CEE).withOpacity(0.5),
                              blurRadius: 30 * (_isRecording ? _pulseAnimation.value : 1.0),
                              spreadRadius: 5 * (_isRecording ? _pulseAnimation.value : 1.0),
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 30),
                Text(
                  _isRecording ? "Tap to Finish" : "Tap to Start",
                  style: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}