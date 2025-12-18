import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'quiz_view.dart';
import '../theme/app_theme.dart'; 
import 'package:flutter_markdown/flutter_markdown.dart';

class NoteDetailsPage extends StatefulWidget {
  final int noteId;
  final String title;

  const NoteDetailsPage({super.key, required this.noteId, required this.title});

  @override
  State<NoteDetailsPage> createState() => _NoteDetailsPageState();
}

class _NoteDetailsPageState extends State<NoteDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String path) async {
    try {
      final url = Supabase.instance.client.storage.from('Lectures').getPublicUrl(path);
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Audio Error: $e")));
    }
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Note?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('notes').delete().eq('id', widget.noteId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteStream = Supabase.instance.client.from('notes').stream(primaryKey: ['id']).eq('id', widget.noteId);

    return Scaffold(
      extendBodyBehindAppBar: true, // Lets the gradient go behind the AppBar
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: AppTheme.deepBlue)),
        backgroundColor: Colors.transparent, // Transparent for gradient
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.deepBlue),
        actions: [
          IconButton(
            onPressed: _deleteNote,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient, // Global Ice Gradient
        ),
        child: StreamBuilder(
          stream: noteStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.isEmpty) return const Center(child: Text("Note deleted"));

            final note = snapshot.data![0];
            final audioPath = note['audio_path'];

            return Column(
              children: [
                const SizedBox(height: 100), // Space for AppBar

                // 1. AUDIO PLAYER CARD (Floating Glass)
                if (audioPath != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 50, color: AppTheme.primaryBlue),
                              onPressed: () {
                                if (_isPlaying) {
                                  _audioPlayer.pause();
                                } else {
                                  _playAudio(audioPath);
                                }
                              },
                            ),
                          ],
                        ),
                        Slider(
                          activeColor: AppTheme.primaryBlue,
                          inactiveColor: AppTheme.lightIce,
                          min: 0,
                          max: _duration.inSeconds.toDouble(),
                          value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                          onChanged: (val) async {
                            await _audioPlayer.seek(Duration(seconds: val.toInt()));
                          },
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // 2. TAB BAR (Pill Style)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.lightIce),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    tabs: const [
                      Tab(text: "Summary"),
                      Tab(text: "Transcript"),
                      Tab(text: "Quiz"),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 3. CONTENT AREA
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // SUMMARY TAB
                      _buildGlassContent(note['summary'] ?? "Generating summary..."),
                      
                      // TRANSCRIPT TAB
                      _buildGlassContent(note['transcript'] ?? "Generating transcript..."),
                      
                      // QUIZ TAB
                      note['quiz'] != null 
                        ? QuizView(questions: note['quiz']) 
                        : const Center(child: Text("Generating quiz...")),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
Widget _buildGlassContent(String text) {
    // 1. ADD SCROLL VIEW HERE
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20), // Outer padding for the scroll
      physics: const BouncingScrollPhysics(), // Adds that nice "bounce" effect
      child: Container(
        // Removed margin here because we put padding on the ScrollView above
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), // Readable white background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05), 
              blurRadius: 15, 
              offset: const Offset(0, 5)
            )
          ],
        ),
        // 2. THE MARKDOWN CONTENT
        child: MarkdownBody(
          data: text,
          selectable: true, 
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
            h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.deepBlue),
            h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepBlue),
            strong: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
            listBullet: const TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
          ),
        ),
      ),
    );
  }
}