import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int noteId; // Required for context
  final String noteTitle;

  const ChatScreen({super.key, required this.noteId, required this.noteTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _userId = Supabase.instance.client.auth.currentUser?.id;
  bool _isSending = false;

  // 1. STREAM: Listen to DB changes in Real-Time
  Stream<List<Map<String, dynamic>>> get _chatStream =>
      Supabase.instance.client
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('note_id', widget.noteId)
          .order('created_at', ascending: true);

  // 2. ACTION: Send Message to DB
  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      await Supabase.instance.client.from('chat_messages').insert({
        'user_id': _userId,
        'note_id': widget.noteId,
        'question': text,
        'response': null, // AI will fill this later
      });
      
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Orbs
          Positioned(top: -100, left: -100, child: _buildOrb(500, const Color(0xFF0D7FF2).withOpacity(0.2))),
          Positioned(bottom: -100, right: -100, child: _buildOrb(500, Colors.purple.withOpacity(0.1))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                
                // MAIN CHAT AREA
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                      }

                      final messages = snapshot.data!;
                      
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            "Ask me anything about\n${widget.noteTitle}",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.3)),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          // Each DB row is ONE interaction (Question + Answer)
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. User Question
                              _MessageBubble(text: msg['question'], isUser: true),
                              
                              // 2. AI Response (or Loading)
                              if (msg['response'] != null)
                                _MessageBubble(text: msg['response'], isUser: false)
                              else
                                const _TypingIndicator(), // Show typing if response is null
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS (Kept mostly same as your design) ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black.withOpacity(0.2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.noteTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text("AI ACTIVE", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Ask a question...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: Color(0xFF0D7FF2), shape: BoxShape.circle),
              child: _isSending 
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isUser ? const LinearGradient(colors: [Color(0xFF0D7FF2), Color(0xFF00C6FF)]) : null,
          color: isUser ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: isUser
            ? Text(text, style: const TextStyle(color: Colors.white))
            : MarkdownBody(data: text, styleSheet: MarkdownStyleSheet(p: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const SizedBox(
          width: 40, height: 20,
          child: Center(child: Text("...", style: TextStyle(color: Colors.white54, fontSize: 20, letterSpacing: 2))),
        ),
      ),
    );
  }
}