import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: const Color(0xFF0F172A), // Dark Lumen Background
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. BACKGROUND ORBS
          Positioned(
            top: -100, right: -100,
            child: _buildOrb(400, Colors.purple.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: _buildOrb(300, const Color(0xFF2B8CEE).withOpacity(0.15)), // Blue
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // HEADER
                _buildHeader(),

                // LIST
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _notesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF2B8CEE)));
                      }
                      
                      final notes = snapshot.data!;
                      
                      if (notes.isEmpty) return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        physics: const BouncingScrollPhysics(),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return _buildChatCard(note);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select a Tutor",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Chat with your study materials",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.search, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> note) {
    // Generate a random gradient based on ID for variety
    final gradients = [
      [const Color(0xFF2B8CEE), const Color(0xFF00C6FF)], // Blue
      [const Color(0xFF8B5CF6), const Color(0xFFD946EF)], // Purple
      [const Color(0xFF10B981), const Color(0xFF34D399)], // Green
    ];
    final gradient = gradients[note['id'] % gradients.length];

    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          color: Colors.white.withOpacity(0.03), // Glass effect
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: gradient[0].withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note['title'] ?? "Untitled",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: gradient[1]),
                            const SizedBox(width: 4),
                            Text(
                              "Tap to start session",
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white.withOpacity(0.2)),
          ),
          const SizedBox(height: 20),
          Text(
            "No lectures found",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Record a lecture to start chatting!",
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
          ),
        ],
      ),
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