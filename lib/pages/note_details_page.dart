import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoteDetailsPage extends StatelessWidget {
  final int noteId;
  final String title;

  const NoteDetailsPage({super.key, required this.noteId, required this.title});

  @override
  Widget build(BuildContext context) {
    // We use a Stream so the page updates LIVE when the AI finishes!
    final noteStream = Supabase.instance.client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('id', noteId);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder(
        stream: noteStream,
        builder: (context, snapshot) {
          // 1. Loading State
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final note = snapshot.data!.first;
          final status = note['status'];

          // 2. Processing State (AI is still thinking)
          if (status == 'Processing') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("AI is analyzing this lecture..."),
                  Text("Please wait a moment."),
                ],
              ),
            );
          }

          // 3. Error State
          if (status == 'Error') {
            return const Center(
                child: Text("❌ AI failed to process this audio.",
                    style: TextStyle(color: Colors.red)));
          }

          // 4. Success State - Show the Tabs
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.summarize), text: "Summary"),
                    Tab(icon: Icon(Icons.description), text: "Transcript"),
                    Tab(icon: Icon(Icons.quiz), text: "Quiz"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Summary
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          note['summary'] ?? "No summary available.",
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                      
                      // Tab 2: Transcript
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          note['transcript'] ?? "No transcript available.",
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),

                      // Tab 3: Quiz (Placeholder for now)
                      Center(child: Text("Quiz Mode Coming Soon!")),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}