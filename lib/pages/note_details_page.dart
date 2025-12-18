import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'quiz_view.dart';

class NoteDetailsPage extends StatefulWidget {
  final int noteId;
  final String title;

  const NoteDetailsPage({super.key, required this.noteId, required this.title});

  @override
  State<NoteDetailsPage> createState() => _NoteDetailsPageState();
}

class _NoteDetailsPageState extends State<NoteDetailsPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        final url = await Supabase.instance.client.storage
            .from('Lectures') 
            .createSignedUrl(audioPath, 3600);
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- DELETE FUNCTION ---
  Future<void> _deleteNote(int id, String audioPath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Lecture?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Delete file
      await Supabase.instance.client.storage.from('Lectures').remove([audioPath]);
      // 2. Delete DB row
      await Supabase.instance.client.from('notes').delete().eq('id', id);
      
      if (mounted) {
        Navigator.pop(context); // Go back to Home
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted successfully")));
      }
    } catch (e) {
      // Ignore storage errors (file might not exist), just ensure DB row is gone
       await Supabase.instance.client.from('notes').delete().eq('id', id);
       if(mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteStream = Supabase.instance.client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('id', widget.noteId);

    return StreamBuilder(
      stream: noteStream,
      builder: (context, snapshot) {
        // Handle Loading/Errors gracefully
        if (!snapshot.hasData) {
          return Scaffold(appBar: AppBar(title: Text(widget.title)), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data!.isEmpty) {
           return Scaffold(appBar: AppBar(title: const Text("Deleted")), body: const Center(child: Text("Note no longer exists.")));
        }

        final note = snapshot.data!.first;
        final status = note['status'];
        final audioPath = note['audio_path'];

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // DELETE BUTTON
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteNote(widget.noteId, audioPath),
              ),
            ],
          ),
          body: Column(
            children: [
              // AUDIO PLAYER
              if (status != 'Processing')
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.blue[50],
                  child: Column(
                    children: [
                      IconButton(
                        iconSize: 48,
                        color: Colors.blue,
                        icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                        onPressed: () => _playAudio(audioPath),
                      ),
                      Slider(
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        value: _position.inSeconds.toDouble(),
                        onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
                      ),
                    ],
                  ),
                ),

              // TABS
              Expanded(
                child: DefaultTabController(
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
                            SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(note['summary'] ?? "No summary.")),
                            SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(note['transcript'] ?? "No transcript.")),
                            note['quiz'] != null ? QuizView(questions: note['quiz']) : const Center(child: Text("No quiz available.")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}