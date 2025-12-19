import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatScreen extends StatefulWidget {
  final int noteId;
  final String noteTitle;

  const ChatScreen({super.key, required this.noteId, required this.noteTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  // 1. THE REAL-TIME STREAM
  Stream<List<Map<String, dynamic>>> get _chatStream {
    return Supabase.instance.client
        .from('chat_messages')
        .stream(primaryKey: ['id']) // Listens for INSERT and UPDATE
        .eq('note_id', widget.noteId)
        .order('created_at', ascending: true);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      // 2. INSERT QUESTION (Response is NULL initially)
      await Supabase.instance.client.from('chat_messages').insert({
        'note_id': widget.noteId,
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'question': text,
        'response': null, // Explicitly null so we know it's pending
      });
      
      // Auto-scroll to bottom
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat: ${widget.noteTitle}", style: const TextStyle(color: AppTheme.deepBlue, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.deepBlue),
      ),
      body: Column(
        children: [
          // 3. CHAT LIST
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Text("Start the conversation!", style: TextStyle(color: Colors.grey)));
                }
                
                final messages = snapshot.data!;
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final question = msg['question'];
                    final answer = msg['response'];
                    
                    return Column(
                      children: [
                        // USER BUBBLE
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8, left: 50),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 5)],
                            ),
                            child: Text(question, style: const TextStyle(color: Colors.white)),
                          ),
                        ),

                        // AI BUBBLE
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20, right: 30),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                              border: Border.all(color: AppTheme.lightIce),
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
                            ),
                            child: answer == null
                                // SHOW LOADING IF ANSWER IS NULL
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                                      SizedBox(width: 10),
                                      Text("Thinking...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                    ],
                                  )
                                // SHOW MARKDOWN ANSWER
                                : MarkdownBody(
                                    data: answer,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(color: Colors.black87, height: 1.5),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 4. INPUT AREA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask about this lecture...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppTheme.lightIce,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: IconButton(
                    icon: _isSending 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}