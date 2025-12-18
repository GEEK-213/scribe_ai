import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
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
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    
    // Listen to player state changes (Playing/Paused)
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    // Listen to audio position (Progress bar)
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() => _duration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() => _position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Clean up when leaving page
    super.dispose();
  }

  // Function to get the File URL and Play it
  Future<void> _playAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // 1. Get the public/signed URL from Supabase
        // We use createSignedUrl to ensure we can access it for 60 mins
        final url = await Supabase.instance.client.storage
            .from('Lectures')
            .createSignedUrl(audioPath, 3600); // Valid for 1 hour

        // 2. Play the URL
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing audio: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // STREAM: Watch this specific note
    final noteStream = Supabase.instance.client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('id', widget.noteId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder(
        stream: noteStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final note = snapshot.data!.first;
          final status = note['status'];
          final audioPath = note['audio_path'];

          // UI Helper: Format duration (e.g. 02:15)
          String formatTime(Duration d) {
            String twoDigits(int n) => n.toString().padLeft(2, "0");
            return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
          }

          if (status == 'Processing') {
            return const Center(child: Text("AI is still processing..."));
          }

          return Column(
            children: [
              // --- AUDIO PLAYER SECTION ---
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.blue[50], // Light blue background
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 48,
                          color: Colors.blue,
                          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                          onPressed: () => _playAudio(audioPath),
                        ),
                      ],
                    ),
                    Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble(),
                      onChanged: (value) async {
                        final position = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                    ),
                    Text("${formatTime(_position)} / ${formatTime(_duration)}"),
                  ],
                ),
              ),

              // --- TABS SECTION ---
              Expanded(
                child: DefaultTabController(
                  length: 2, // Reduced to 2 for now (Summary & Transcript)
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(icon: Icon(Icons.summarize), text: "Summary"),
                          Tab(icon: Icon(Icons.description), text: "Transcript"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 1. Summary Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                note['summary'] ?? "No summary.",
                                style: const TextStyle(fontSize: 16, height: 1.5),
                              ),
                            ),
                            // 2. Transcript Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                note['transcript'] ?? "No transcript.",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}