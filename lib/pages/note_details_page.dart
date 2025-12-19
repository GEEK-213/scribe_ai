import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flip_card/flip_card.dart'; 
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'quiz_view.dart';

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
    // INCREASED TABS TO 4 (Summary, Transcript, Quiz, Cards)
    _tabController = TabController(length: 4, vsync: this); 
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String path) async {
    try {
      // Try lowercase bucket first, then capitalized
      String url;
      try {
        url = Supabase.instance.client.storage.from('Lectures').getPublicUrl(path);
      } catch (e) {
        url = Supabase.instance.client.storage.from('Lectures').getPublicUrl(path);
      }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: AppTheme.deepBlue)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.deepBlue),
        actions: [
          // Chat Button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryBlue),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(
                 builder: (_) => ChatScreen(noteId: widget.noteId, noteTitle: widget.title),
               ));
            },
          ),
          // Delete Button
          IconButton(
            onPressed: _deleteNote,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: StreamBuilder(
          stream: noteStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.isEmpty) return const Center(child: Text("Note deleted"));

            final note = snapshot.data![0];
            final audioPath = note['audio_path'];

            return Column(
              children: [
                const SizedBox(height: 100),

                // 1. AUDIO PLAYER CARD
                if (audioPath != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10)]
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

                // 2. TAB BAR
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
                      Tab(text: "Cards"), // <--- NEW TAB
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 3. TAB CONTENT
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGlassContent(note['summary'] ?? "Generating..."),
                      _buildGlassContent(note['transcript'] ?? "Generating..."),
                      note['quiz'] != null ? QuizView(questions: note['quiz']) : const Center(child: Text("Generating quiz...")),
                      _buildFlashcardsView(widget.noteId), // <--- NEW VIEW
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

  // --- MARKDOWN HELPER ---
  Widget _buildGlassContent(String text) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15)],
        ),
        child: MarkdownBody(
          data: text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
            h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.deepBlue),
            h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepBlue),
            listBullet: const TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
            strong: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // --- FLASHCARDS WIDGET (The New Feature!) ---
  Widget _buildFlashcardsView(int noteId) {
    // Fetch cards related to this specific note
    final stream = Supabase.instance.client
        .from('flashcards')
        .stream(primaryKey: ['id'])
        .eq('note_id', noteId);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final cards = snapshot.data!;

        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                const Text("No flashcards found.", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                const Text("Upload a new file to generate them!", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return Container(
              height: 200, // Fixed height for consistency
              margin: const EdgeInsets.only(bottom: 20),
              child: FlipCard(
                direction: FlipDirection.HORIZONTAL,
                front: _buildCardFace(card['front'], AppTheme.primaryBlue, Colors.white, "Tap to Flip"),
                back: _buildCardFace(card['back'], Colors.white, Colors.black87, "Definition"),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardFace(String text, Color bgColor, Color textColor, String subText) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        border: bgColor == Colors.white ? Border.all(color: AppTheme.lightIce, width: 2) : null,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subText, 
            style: TextStyle(
              fontSize: 12, 
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic
            )
          ),
        ],
      ),
    );
  }
}