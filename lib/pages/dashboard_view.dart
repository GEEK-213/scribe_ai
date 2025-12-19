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

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Folder"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Folder Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await Supabase.instance.client.from('folders').insert({
                  'name': controller.text,
                  'user_id': _userId,
                });
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
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await Supabase.instance.client
                    .from('notes')
                    .update({'title': controller.text})
                    .eq('id', noteId);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- NEW: Move Note Logic ---
  Future<void> _moveNote(int noteId) async {
    // 1. Get list of current folders
    final folders = await Supabase.instance.client
        .from('folders')
        .select()
        .eq('user_id', _userId!);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Move to...'),
          children: [
            // Option: Remove from any folder (Back to All Notes)
            SimpleDialogOption(
              onPressed: () async {
                await Supabase.instance.client
                    .from('notes')
                    .update({'folder_id': null}) 
                    .eq('id', noteId);
                if (mounted) Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(children: [Icon(Icons.folder_off, color: Colors.grey), SizedBox(width: 10), Text("Remove from Folder")]),
              ),
            ),
            const Divider(),
            // Option: List existing folders
            ...folders.map((folder) => SimpleDialogOption(
              onPressed: () async {
                await Supabase.instance.client
                    .from('notes')
                    .update({'folder_id': folder['id']})
                    .eq('id', noteId);
                if (mounted) Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(children: [const Icon(Icons.folder, color: Colors.blue), const SizedBox(width: 10), Text(folder['name'])]),
              ),
            )),
          ],
        );
      }
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
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success! Processing.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mainGradient, 
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30)
              ),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("My Library 📚", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                SizedBox(
                  height: 40,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _foldersStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final folders = snapshot.data!;
                      
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFolderChip("All Notes", -1),
                          ...folders.map((folder) => _buildFolderChip(folder['name'], folder['id'])),
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

          // Buttons
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

          const SizedBox(height: 10),

          // Notes List
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
                   return Center(
                     child: Text(
                       _selectedFolderId == -1 ? "No Lectures yet." : "This folder is empty.",
                       style: const TextStyle(color: Colors.grey),
                     ),
                   );
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
                        
                        // Menu with Rename AND Move
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'rename') {
                              _renameNote(note['id'].toString(), note['title'] ?? '');
                            } else if (value == 'move') {
                              _moveNote(note['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue, size: 20),
                                  SizedBox(width: 10),
                                  Text("Rename"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'move',
                              child: Row(
                                children: [
                                  Icon(Icons.drive_file_move, color: Colors.orange, size: 20),
                                  SizedBox(width: 10),
                                  Text("Move to..."),
                                ],
                              ),
                            ),
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
          if (selected) {
            setState(() {
              _selectedFolderId = id;
            });
          }
        },
        selectedColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.deepBlue : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? Colors.white : Colors.transparent)
        ),
      ),
    );
  }
}