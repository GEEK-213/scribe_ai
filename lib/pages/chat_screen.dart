import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // Import theme

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

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    
    // Send to Supabase
    await Supabase.instance.client.from('chat_messages').insert({
      'user_id': Supabase.instance.client.auth.currentUser!.id,
      'note_id': widget.noteId,
      'question': text,
      // 'response' is null initially, AI will fill it
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatStream = Supabase.instance.client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('note_id', widget.noteId)
        .order('created_at', ascending: true);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.noteTitle, style: const TextStyle(color: AppTheme.deepBlue)),
        backgroundColor: Colors.white.withOpacity(0.8), // Semi-transparent header
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.deepBlue),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient, // Ice Theme
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: chatStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!;

                  // Auto-scroll to bottom
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  if (messages.isEmpty) {
                    return Center(
                      child: Text("Ask anything about this lecture!", 
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Column(
                        children: [
                          // USER QUESTION (Right Side)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(0), // Sharp edge
                                ),
                              ),
                              child: Text(msg['question'], style: const TextStyle(color: Colors.white, fontSize: 15)),
                            ),
                          ),
                          
                          // AI RESPONSE (Left Side)
                          if (msg['response'] != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(16),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(0), // Sharp edge
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                                  ]
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.auto_awesome, size: 14, color: AppTheme.accentPurple),
                                        const SizedBox(width: 5),
                                        Text("AI Tutor", style: TextStyle(fontSize: 12, color: AppTheme.accentPurple, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(msg['response'], style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.4)),
                                  ],
                                ),
                              ),
                            )
                          else
                            // TYPING INDICATOR
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12, height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text("Thinking...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
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
            
            // INPUT BAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
                ]
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.lightIce,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: "Ask a question...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}