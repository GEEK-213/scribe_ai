import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class ChatSelectionPage extends StatelessWidget {
  const ChatSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final notesStream = Supabase.instance.client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId ?? '')
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Select a Lecture")),
      body: StreamBuilder(
        stream: notesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notes = snapshot.data!;
          
          if (notes.isEmpty) return const Center(child: Text("No lectures found. Record one first!"));

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  title: Text(note['title'] ?? "Untitled"),
                  subtitle: const Text("Chat with this lecture"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          noteId: note['id'],
                          noteTitle: note['title'] ?? "Lecture",
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
    );
  }
}