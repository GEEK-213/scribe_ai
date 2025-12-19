import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'record_page.dart';
import 'note_details_page.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _userId = Supabase.instance.client.auth.currentUser?.id;
  int _selectedFolderId = -1; 

  // --- STREAMS ---
  Stream<List<Map<String, dynamic>>> get _foldersStream {
    return Supabase.instance.client
        .from('folders')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId ?? '')
        .order('created_at');
  }

  Stream<List<Map<String, dynamic>>> get _notesStream {
    return Supabase.instance.client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId ?? '')
        .order('created_at', ascending: false);
  }

  // NEW: Stream for Tasks
  Stream<List<Map<String, dynamic>>> get _tasksStream {
    return Supabase.instance.client
        .from('study_tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId ?? '')
        .order('id', ascending: false);
  }

  // --- ACTIONS ---
  Future<void> _createFolder() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Folder"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Folder Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await Supabase.instance.client.from('folders').insert({'name': controller.text, 'user_id': _userId});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _renameNote(String noteId, String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename File"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "New Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await Supabase.instance.client.from('notes').update({'title': controller.text}).eq('id', noteId);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _moveNote(int noteId) async {
    final folders = await Supabase.instance.client.from('folders').select().eq('user_id', _userId!);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Move to...'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await Supabase.instance.client.from('notes').update({'folder_id': null}).eq('id', noteId);
              if (mounted) Navigator.pop(context);
            },
            child: const Padding(padding: EdgeInsets.all(8.0), child: Row(children: [Icon(Icons.folder_off, color: Colors.grey), SizedBox(width: 10), Text("Remove from Folder")])),
          ),
          const Divider(),
          ...folders.map((f) => SimpleDialogOption(
            onPressed: () async {
              await Supabase.instance.client.from('notes').update({'folder_id': f['id']}).eq('id', noteId);
              if (mounted) Navigator.pop(context);
            },
            child: Padding(padding: const EdgeInsets.all(8.0), child: Row(children: [const Icon(Icons.folder, color: Colors.blue), const SizedBox(width: 10), Text(f['name'])])),
          )),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'pdf', 'txt', 'docx'], 
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_upload.${result.files.single.extension}';

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading...')));

      await Supabase.instance.client.storage.from('Lectures').upload(fileName, file);

      await Supabase.instance.client.from('notes').insert({
        'title': 'Upload ${DateTime.now().hour}:${DateTime.now().minute}',
        'audio_path': fileName,
        'status': 'Processing',
        'user_id': _userId,
        'folder_id': _selectedFolderId == -1 ? null : _selectedFolderId,
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success! AI is processing.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // NEW: Mark Task as Complete
  Future<void> _toggleTask(int taskId) async {
    await Supabase.instance.client
        .from('study_tasks')
        .update({'is_completed': true})
        .eq('id', taskId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
      child: Column(
        children: [
          // 1. HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("My Library 📚", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                // Folder List
                SizedBox(
                  height: 40,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _foldersStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFolderChip("All Notes", -1),
                          ...snapshot.data!.map((f) => _buildFolderChip(f['name'], f['id'])),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              onPressed: _createFolder,
                              icon: const Icon(Icons.add_circle, color: Colors.white70),
                              tooltip: "Create Folder",
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 15),

          // 2. ACTION BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordPage())),
                    icon: const Icon(Icons.mic),
                    label: const Text("Record"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickAndUploadFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: AppTheme.deepBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. NEW: TASKS SECTION
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _tasksStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink(); // Hide if empty
              
              final tasks = snapshot.data!;
              return Container(
                height: 140, // Fixed height for task scroller
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Padding(
                       padding: EdgeInsets.symmetric(horizontal: 20),
                       child: Text("Upcoming Tasks ⚡", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                     ),
                     const SizedBox(height: 10),
                     Expanded(
                       child: ListView.builder(
                         scrollDirection: Axis.horizontal,
                         padding: const EdgeInsets.symmetric(horizontal: 20),
                         itemCount: tasks.length,
                         itemBuilder: (context, index) {
                           final task = tasks[index];
                           return Container(
                             width: 200,
                             margin: const EdgeInsets.only(right: 10),
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.9),
                               borderRadius: BorderRadius.circular(15),
                               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(task['title'] ?? 'Task', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Text(task['due_date'] ?? 'No Date', style: const TextStyle(fontSize: 12, color: Colors.red)),
                                     IconButton(
                                       icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                       onPressed: () => _toggleTask(task['id']),
                                       tooltip: "Mark Complete",
                                     )
                                   ],
                                 )
                               ],
                             ),
                           );
                         },
                       ),
                     ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),
          
          const Padding(
             padding: EdgeInsets.only(left: 20, top: 10),
             child: Align(alignment: Alignment.centerLeft, child: Text("Recent Files", style: TextStyle(color: Colors.white70, fontSize: 14))),
          ),

          // 4. NOTES LIST
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _notesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final allNotes = snapshot.data!;
                final visibleNotes = _selectedFolderId == -1 
                    ? allNotes 
                    : allNotes.where((n) => n['folder_id'] == _selectedFolderId).toList();

                if (visibleNotes.isEmpty) {
                   return Center(child: Text(_selectedFolderId == -1 ? "No Lectures yet." : "This folder is empty.", style: const TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: visibleNotes.length,
                  itemBuilder: (context, index) {
                    final note = visibleNotes[index];
                    final isDone = note['status'] == 'Done';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDone ? Colors.green.shade50 : Colors.orange.shade50,
                          child: Icon(isDone ? Icons.check : Icons.hourglass_empty, color: isDone ? Colors.green : Colors.orange),
                        ),
                        title: Text(note['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(isDone ? "Tap to review" : "AI Processing...", style: const TextStyle(fontSize: 12)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'rename') _renameNote(note['id'].toString(), note['title'] ?? '');
                            if (val == 'move') _moveNote(note['id']);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 10), Text("Rename")])),
                            const PopupMenuItem(value: 'move', child: Row(children: [Icon(Icons.folder, color: Colors.orange), SizedBox(width: 10), Text("Move")])),
                          ],
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailsPage(noteId: note['id'], title: note['title'] ?? 'Lecture'))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderChip(String label, int id) {
    final isSelected = _selectedFolderId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFolderId = id);
        },
        selectedColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.2),
        labelStyle: TextStyle(color: isSelected ? AppTheme.deepBlue : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.white : Colors.transparent)),
      ),
    );
  }
}