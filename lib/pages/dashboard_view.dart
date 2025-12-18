import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'record_page.dart';
import 'note_details_page.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _userId = Supabase.instance.client.auth.currentUser?.id;

  late final _notesStream = Supabase.instance.client
      .from('notes')
      .stream(primaryKey: ['id'])
      .eq('user_id', _userId ?? '')
      .order('created_at', ascending: false);

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'mp4', 'mkv'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_upload.${result.files.single.extension}';

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading...')));

      await Supabase.instance.client.storage.from('lectures').upload(fileName, file);

      await Supabase.instance.client.from('notes').insert({
        'title': 'Upload ${DateTime.now().hour}:${DateTime.now().minute}',
        'audio_path': fileName,
        'status': 'Processing',
        'user_id': _userId,
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success! AI is processing.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. FIXED HEADER
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome Back! 👋", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Let's crush your studies today.", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatCard("Lectures", "Checking...", Icons.mic),
                  const SizedBox(width: 10),
                  _buildStatCard("Avg Quiz", "85%", Icons.emoji_events),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 15),

        // 2. ACTION BUTTONS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordPage())),
                  icon: const Icon(Icons.mic),
                  label: const Text("Record"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickAndUploadFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 3. SCROLLING LIST
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final notes = snapshot.data!;

              if (notes.isEmpty) return const Center(child: Text("No lectures yet."));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final isDone = note['status'] == 'Done';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDone ? Colors.green.shade100 : Colors.orange.shade100,
                        child: Icon(isDone ? Icons.check : Icons.hourglass_empty, color: isDone ? Colors.green : Colors.orange),
                      ),
                      title: Text(note['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(isDone ? "Tap to review" : "AI Processing...", style: const TextStyle(fontSize: 12)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailsPage(noteId: note['id'], title: note['title'] ?? 'Lecture'))),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}