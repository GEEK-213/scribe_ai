import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  // 1. Create the Audio Recorder instance
  late final AudioRecorder _audioRecorder;
  
  // State variables
  bool _isRecording = false;
  String? _audioPath; // To store where the file is saved

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose(); // Always clean up
    super.dispose();
  }

  // 2. Function to Start Recording
  Future<void> _startRecording() async {
    try {
      // Check if we have permission
      if (await _audioRecorder.hasPermission()) {
        
        // Get a safe location to save the file
        final directory = await getApplicationDocumentsDirectory();
        // Create a unique filename using the current time
        final String filePath = '${directory.path}/lecture_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording to that file
        await _audioRecorder.start(const RecordConfig(), path: filePath);

        setState(() {
          _isRecording = true;
          _audioPath = filePath;
        });
        print("Recording started at: $filePath");
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  // 3. Function to Stop Recording
 Future<void> _stopRecording() async {
    try {
      // 1. Stop recording locally
      final path = await _audioRecorder.stop();
      if (path == null) return;

      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading to Cloud...')),
        );
      }

      // 2. Upload File to Storage
      final file = File(path);
      // Create a clean filename (e.g., "1708842_lecture.m4a")
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_lecture.m4a';

      await Supabase.instance.client.storage
          .from('Lectures')
          .upload(fileName, file);

      // 3. Create Database Entry (The "Trigger")
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      await Supabase.instance.client.from('notes').insert({
        'title': 'New Lecture ${DateTime.now().hour}:${DateTime.now().minute}',
        'audio_path': fileName,
        'status': 'Processing', // This tells Python "Hey, work on this!"
        'user_id': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved! AI is analyzing...')),
        );
        Navigator.pop(context); // Go back to Home
      }
      
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Lecture')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Text
            Text(
              _isRecording ? 'Recording...' : 'Tap Mic to Start',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // The Big Red Button
            GestureDetector(
              onTap: () {
                if (_isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            if (_audioPath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Last saved: $_audioPath", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }
}