import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'record_page.dart';
import 'note_details_page.dart'; 
import 'package:file_picker/file_picker.dart';
import 'dart:io'; 


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // STREAM: This listens to the 'notes' table in real-time
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  // STREAM: Listen ONLY to notes that belong to this user
  late final _notesStream = Supabase.instance.client
      .from('notes')
      .stream(primaryKey: ['id'])
      .eq('user_id', _userId) // <--- THIS IS THE SECURITY FILTER
      .order('created_at', ascending: false);

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginPage())
      );
    }
  }

// FUNCTION: Pick a file and upload it
  Future<void> _pickAndUploadFile() async {
    try {
      // 1. Open File Picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'mp4', 'mkv'], // Audio & Video
      );

      if (result == null) return; // User canceled

      // 2. Get the file
      final file = File(result.files.single.path!);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_upload.${result.files.single.extension}';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading file... this may take time.')),
        );
      }

      // 3. Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from('Lectures')
          .upload(fileName, file);

      // 4. Create Database Entry
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('notes').insert({
        'title': 'Uploaded File ${DateTime.now().hour}:${DateTime.now().minute}',
        'audio_path': fileName,
        'status': 'Processing',
        'user_id': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload Complete! AI is processing.')),
        );
      }
    } catch (e) {
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
      appBar: AppBar(
        title: const Text('My Lectures'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      
      // BODY: Replaced static list with Real Database Data
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notesStream,
        builder: (context, snapshot) {
          // 1. Loading State
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!;

          // 2. Empty State
          if (notes.isEmpty) {
            return const Center(
              child: Text("No lectures recorded yet.\nTap the mic to start!", 
                textAlign: TextAlign.center),
            );
          }

          // 3. List of Notes
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final status = note['status'] ?? 'Pending';
              final isDone = status == 'Done';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(
                    isDone ? Icons.check_circle : Icons.sync, 
                    color: isDone ? Colors.green : Colors.orange
                  ),
                  title: Text(note['title'] ?? 'Untitled Lecture'),
                  subtitle: Text(
                    isDone ? "Tap to view summary" : "AI is processing...",
                    style: TextStyle(
                      color: isDone ? Colors.grey : Colors.orange[800],
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  
                  // NAVIGATION LOGIC
                  onTap: () {
                    // Only open details if it is ready (or you can let them verify status)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteDetailsPage(
                          noteId: note['id'], 
                          title: note['title'] ?? 'Lecture',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // RECORD BUTTON
      // UPDATED BUTTONS (Row of 2)
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 1. Upload Button (White)
          FloatingActionButton.extended(
            heroTag: "upload_btn",
            onPressed: _pickAndUploadFile, // Calls your new function!
            label: const Text('Upload'),
            icon: const Icon(Icons.upload_file),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          const SizedBox(width: 10), // Space between buttons
          
          // 2. Record Button (Red)
          FloatingActionButton.extended(
            heroTag: "record_btn",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecordPage()),
              );
            },
            label: const Text('Record'),
            icon: const Icon(Icons.mic),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}