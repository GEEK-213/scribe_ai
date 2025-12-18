import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'record_page.dart';
import 'note_details_page.dart'; 


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // STREAM: This listens to the 'notes' table in real-time
  final _notesStream = Supabase.instance.client
      .from('notes')
      .stream(primaryKey: ['id'])
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecordPage()),
          );
        },
        label: const Text('New Lecture'),
        icon: const Icon(Icons.mic),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}