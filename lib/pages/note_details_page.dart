import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
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

  const NoteDetailsPage({
    super.key,
    required this.noteId,
    required this.title,
  });

  @override
  State<NoteDetailsPage> createState() => _NoteDetailsPageState();
}

class _NoteDetailsPageState extends State<NoteDetailsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
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

  // ================= AUDIO =================

  Future<void> _playAudio(String path) async {
    try {
      final url = Supabase.instance.client.storage.from('Lectures').getPublicUrl(path);
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  // ================= DELETE =================

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Note?", style: TextStyle(color: Colors.white)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('notes').delete().eq('id', widget.noteId);
      if (mounted) Navigator.pop(context);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final noteStream = Supabase.instance.client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('id', widget.noteId);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Lumen Dark Background
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          // 1. AMBIENT GLOW (Lumen Style)
          Positioned(
            top: -100, right: -100,
            child: _buildOrb(400, const Color(0xFF2B8CEE).withOpacity(0.15)), // Blue Glow
          ),
          Positioned(
            bottom: -50, left: -50,
            child: _buildOrb(300, const Color(0xFF8B5CF6).withOpacity(0.1)), // Purple Glow
          ),

          // 2. MAIN CONTENT
          SafeArea(
            bottom: false,
            child: StreamBuilder(
              stream: noteStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                if (snapshot.data!.isEmpty) return const Center(child: Text("Note not found", style: TextStyle(color: Colors.white)));

                final note = snapshot.data![0];
                final audioPath = note['audio_path'];

                return Column(
                  children: [
                    // ===== TOP FIXED SECTION =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (audioPath != null)
                            _GlassAudioPlayer(
                              isPlaying: _isPlaying,
                              position: _position,
                              duration: _duration,
                              onPlayPause: () => _isPlaying ? _audioPlayer.pause() : _playAudio(audioPath),
                              onSeek: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
                            ),
                          const SizedBox(height: 20),
                          _GlassTabSelector(controller: _tabController),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // ===== SCROLLABLE CONTENT =====
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // 1. Summary
                          _GlassMarkdownCard(text: note['summary'] ?? "Generating summary..."),
                          // 2. Transcript
                          _GlassMarkdownCard(text: note['transcript'] ?? "Generating transcript..."),
                          // 3. Quiz
                          note['quiz'] != null 
                              ? QuizView(questions: note['quiz']) 
                              : const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
                          // 4. Flashcards
                          _GlassFlashcardsDeck(
                            noteId: widget.noteId,
                            currentIndex: _currentCardIndex,
                            onIndexChanged: (i) => setState(() => _currentCardIndex = i),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  PreferredSizeWidget _buildGlassAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: const Color(0xFF0F172A).withOpacity(0.6)),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(noteId: widget.noteId, noteTitle: widget.title))),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: _deleteNote,
        ),
      ],
    );
  }

  Widget _buildOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/* ============================================================
   GLASS AUDIO PLAYER
============================================================ */

class _GlassAudioPlayer extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;

  const _GlassAudioPlayer({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              // Play Button
              GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  height: 48, width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppTheme.primaryBlue, Colors.blueAccent]),
                    boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4), blurRadius: 15)],
                  ),
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              // Slider & Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Lecture Audio", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AppTheme.primaryBlue,
                        inactiveTrackColor: Colors.white10,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                        max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1,
                        onChanged: onSeek,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   GLASS TAB SELECTOR
============================================================ */

class _GlassTabSelector extends StatelessWidget {
  final TabController controller;

  const _GlassTabSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4), blurRadius: 10)],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: "Summary"),
          Tab(text: "Text"),
          Tab(text: "Quiz"),
          Tab(text: "Cards"),
        ],
      ),
    );
  }
}

/* ============================================================
   GLASS MARKDOWN CARD (Content)
============================================================ */

class _GlassMarkdownCard extends StatelessWidget {
  final String text;

  const _GlassMarkdownCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: MarkdownBody(
              data: text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70),
                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                listBullet: const TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
                strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                code: TextStyle(backgroundColor: Colors.black.withOpacity(0.3), color: Colors.greenAccent, fontFamily: 'monospace'),
                codeblockDecoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   NEON FLASHCARDS
============================================================ */

class _GlassFlashcardsDeck extends StatelessWidget {
  final int noteId;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _GlassFlashcardsDeck({
    required this.noteId,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client.from('flashcards').stream(primaryKey: ['id']).eq('note_id', noteId);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final cards = snapshot.data!;
        
        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style, size: 60, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 10),
                Text("No flashcards generated", style: TextStyle(color: Colors.white.withOpacity(0.3))),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (currentIndex + 1) / cards.length,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBlue),
                ),
              ),
            ),
            
            // Deck
            Expanded(
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.85),
                itemCount: cards.length,
                onPageChanged: onIndexChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    child: FlipCard(
                      direction: FlipDirection.HORIZONTAL,
                      front: _buildCardFace(cards[i]['front'], true),
                      back: _buildCardFace(cards[i]['back'], false),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildCardFace(String text, bool isFront) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isFront 
            ? const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : const LinearGradient(colors: [AppTheme.primaryBlue, Color(0xFF1E40AF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isFront ? "QUESTION" : "ANSWER", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 20),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}