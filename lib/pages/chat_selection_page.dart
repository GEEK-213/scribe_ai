import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import '../theme/app_theme.dart'; // Import theme

class ChatSelectionPage extends StatefulWidget {
  const ChatSelectionPage({super.key});

  @override
  State<ChatSelectionPage> createState() => _ChatSelectionPageState();
}

class _ChatSelectionPageState extends State<ChatSelectionPage> {
  late final Stream<List<Map<String, dynamic>>> _notesStream;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _notesStream = Supabase.instance.client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId ?? '')
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Lets gradient go behind title
      appBar: AppBar(
        title: const Text("Select a Tutor", style: TextStyle(color: AppTheme.deepBlue)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hides back button (since it's a tab)
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient, // Ice Theme
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _notesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final notes = snapshot.data!;
            
            if (notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined, size: 80, color: AppTheme.primaryBlue.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    const Text("Record a lecture first to chat!", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightIce,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_stories, color: AppTheme.primaryBlue),
                    ),
                    title: Text(
                      note['title'] ?? "Untitled", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    subtitle: const Text("Ask questions about this lecture"),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryBlue),
                    ),
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
      ),
    );
  }
}