import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Run 'flutter pub add intl' if you get an error
import '../theme/app_theme.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final _userId = Supabase.instance.client.auth.currentUser?.id;

  // 1. STREAM: Listen to tasks in real-time
  Stream<List<Map<String, dynamic>>> get _tasksStream =>
      Supabase.instance.client
          .from('study_tasks')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId ?? '')
          .order('is_completed', ascending: true) // Unfinished first
          .order('id', ascending: false);       // Newest first

  // 2. ACTION: Toggle "Done" status
  Future<void> _toggleTask(int id, bool currentValue) async {
    await Supabase.instance.client
        .from('study_tasks')
        .update({'is_completed': !currentValue})
        .eq('id', id);
  }

  // 3. ACTION: Delete Task
  Future<void> _deleteTask(int id) async {
    await Supabase.instance.client.from('study_tasks').delete().eq('id', id);
  }

  // 4. ACTION: Add Manual Task
  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("New Task", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "e.g. Finish Project Report",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await Supabase.instance.client.from('study_tasks').insert({
                  'user_id': _userId,
                  'title': titleController.text,
                  'is_completed': false,
                  'due_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      // Floating Button to add manual tasks
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Text("Study Plan", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text("Today", style: TextStyle(color: Colors.white70)),
                  )
                ],
              ),
            ),

            // Task List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _tasksStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                  
                  final tasks = snapshot.data!;
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 80, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 10),
                          Text("All caught up!", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final isDone = task['is_completed'] as bool;

                      return Dismissible(
                        key: Key(task['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) => _deleteTask(task['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.white.withOpacity(0.02) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDone ? Colors.transparent : Colors.white.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _toggleTask(task['id'], isDone),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: isDone ? Colors.greenAccent : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDone ? Colors.greenAccent : Colors.white54, width: 2),
                                ),
                                child: isDone ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                              ),
                            ),
                            title: Text(
                              task['title'],
                              style: TextStyle(
                                color: isDone ? Colors.white38 : Colors.white,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: task['due_date'] != null
                                ? Text("Due: ${task['due_date']}", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))
                                : null,
                            trailing: task['origin_note_id'] != null
                                ? const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 16) // Icon if AI made it
                                : null,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}