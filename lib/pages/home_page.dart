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
  int _selectedIndex = 0; // For Bottom Navigation

  // GET USER ID
  final _userId = Supabase.instance.client.auth.currentUser?.id;

  // STREAM: Fetch only user's notes
  late final _notesStream = Supabase.instance.client
      .from('notes')
      .stream(primaryKey: ['id'])
      .eq('user_id', _userId ?? '')
      .order('created_at', ascending: false);

  // --- UPLOAD FUNCTION ---
  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'mp4', 'mkv'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_upload.${result.files.single.extension}';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading file...')),
        );
      }

      await Supabase.instance.client.storage.from('lectures').upload(fileName, file);

      await Supabase.instance.client.from('notes').insert({
        'title': 'Upload ${DateTime.now().hour}:${DateTime.now().minute}',
        'audio_path': fileName,
        'status': 'Processing',
        'user_id': _userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload Complete! AI is working.')),
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

  // --- LOGOUT ---
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      
      // TOP APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text('ScribeAI Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout, color: Colors.white))
        ],
      ),

      // BOTTOM NAVIGATION (Preparation for Chatbot & Planner)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'AI Tutor'), // Feature #1
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'), // Feature #4
        ],
      ),

      // BODY
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome Back, Student! 👋", 
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  const Text("Let's crush your studies today.", 
                    style: TextStyle(color: Colors.white70, fontSize: 14)
                  ),
                  const SizedBox(height: 20),
                  
                  // Quick Stats Row
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

            const SizedBox(height: 20),

            // 2. ACTION BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordPage()));
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text("Record"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickAndUploadFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 3. RECENT LECTURES TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Lectures", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                  ),
                  TextButton(onPressed: (){}, child: const Text("View All"))
                ],
              ),
            ),

            // 4. THE LIST (StreamBuilder)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _notesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final notes = snapshot.data!;

                if (notes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text("No lectures yet. Start recording!")),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true, // Vital for scrolling inside SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final isDone = note['status'] == 'Done';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDone ? Colors.green.shade100 : Colors.orange.shade100,
                          child: Icon(
                            isDone ? Icons.check : Icons.hourglass_empty, 
                            color: isDone ? Colors.green : Colors.orange
                          ),
                        ),
                        title: Text(note['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(isDone ? "Tap to review" : "AI Processing...", style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper widget for Stats
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
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