import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int? noteId; // Optional: If chatting about a specific note
  final String? noteTitle;

  const ChatScreen({super.key, this.noteId, this.noteTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    _messages.add(ChatMessage(
      text: "Hello! I am Lumen. How can I illuminate your questions regarding ${widget.noteTitle ?? 'your studies'} today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // --- ACTIONS ---

  void _handleSend() {
    if (_textController.text.trim().isEmpty) return;

    final text = _textController.text;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isTyping = true; // Show typing indicator
    });
    _scrollToBottom();

    // SIMULATED AI RESPONSE (Replace with your Supabase/AI Logic)
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: "That is an interesting point about **$text**. \n\nHere are three key takeaways:\n1. Quantum superposition\n2. Entanglement\n3. Interference",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate
      body: Stack(
        children: [
          // 1. BACKGROUND ORBS
          Positioned(
            top: -100, left: -100,
            child: _buildOrb(500, const Color(0xFF0D7FF2).withOpacity(0.2)), // Primary Blue
          ),
          Positioned(
            bottom: 200, right: -100,
            child: _buildOrb(600, Colors.purple.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -100, left: 50,
            child: _buildOrb(400, Colors.cyan.withOpacity(0.1)),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: _messages[index]);
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white.withOpacity(0.05),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text("Lumen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 5)])),
                          const SizedBox(width: 6),
                          Text("ONLINE", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500)),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {}, 
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 28),
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Ask Lumen anything...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D7FF2),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF0D7FF2).withOpacity(0.5), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// --- HELPER CLASSES ---

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!message.isUser)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 4),
                    child: Text("Lumen", style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: message.isUser 
                      ? const LinearGradient(colors: [Color(0xFF0D7FF2), Color(0xFF00C6FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : null,
                    color: message.isUser ? null : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                    border: message.isUser ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: message.isUser
                      ? Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4))
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                            strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                if (message.isUser)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Read", style: TextStyle(color: Colors.white38, fontSize: 10)),
                        SizedBox(width: 4),
                        Icon(Icons.done_all, size: 12, color: Colors.white38),
                      ],
                    ),
                  ),
                if (!message.isUser) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _actionButton(Icons.refresh, "Regenerate"),
                      const SizedBox(width: 8),
                      _actionButton(Icons.copy, "Copy"),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        image: const DecorationImage(image: NetworkImage("https://i.pravatar.cc/150?img=5"), fit: BoxFit.cover),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy, color: Color(0xFF0D7FF2), size: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4)),
            ),
            child: Row(
              children: List.generate(3, (index) {
                return FadeTransition(
                  opacity: Tween(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeInOut))),
                  child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle)),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}