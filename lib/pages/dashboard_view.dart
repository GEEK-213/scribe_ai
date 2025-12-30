import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import 'record_page.dart';
import 'note_details_page.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _userId = Supabase.instance.client.auth.currentUser?.id;
  int _selectedFolderId = -1; // -1 represents "All"
  String _searchQuery = "";

  // --- STREAMS ---
  Stream<List<Map<String, dynamic>>> get _foldersStream =>
      Supabase.instance.client.from('folders').stream(primaryKey: ['id']).eq('user_id', _userId ?? '').order('created_at');

  Stream<List<Map<String, dynamic>>> get _notesStream =>
      Supabase.instance.client.from('notes').stream(primaryKey: ['id']).eq('user_id', _userId ?? '').order('created_at', ascending: false);

  Stream<List<Map<String, dynamic>>> get _tasksStream =>
      Supabase.instance.client.from('study_tasks').stream(primaryKey: ['id']).eq('user_id', _userId ?? '').order('id', ascending: false);

  // --- ACTIONS ---

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'pdf', 'txt', 'docx'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_upload.${result.files.single.extension}';

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading to Lumen Cloud...')));

      // Upload to Storage
      await Supabase.instance.client.storage.from('Lectures').upload(fileName, file);

      // Insert into Database
      await Supabase.instance.client.from('notes').insert({
        'title': result.files.single.name,
        'audio_path': fileName,
        'status': 'Processing', // Triggers AI
        'user_id': _userId,
        'folder_id': _selectedFolderId == -1 ? null : _selectedFolderId,
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _createFolderDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B), // Dark Slate
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text("New Subject", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "e.g., Physics, History",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await Supabase.instance.client.from('folders').insert({'name': controller.text, 'user_id': _userId});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- MAIN UI ---
  @override
  Widget build(BuildContext context) {
    // 1. REMOVE SCAFFOLD: We use a Container/Stack because HomePage already has the Scaffold
    return Container(
      color: AppTheme.backgroundDark,
      child: Stack(
        children: [
          // A. BACKGROUND ORBS (Ambient Glow)
          Positioned(
            top: -100, left: -100,
            child: _buildOrb(300, const Color(0xFF2B8CEE).withOpacity(0.4)), // Primary Blue
          ),
          Positioned(
            bottom: 100, right: -100,
            child: _buildOrb(400, const Color(0xFF4AA3FF).withOpacity(0.2)), // Light Blue
          ),

          // B. MAIN SCROLL VIEW
          SafeArea(
            bottom: false, 
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader()),

                // Search Bar
                SliverToBoxAdapter(child: _buildSearchBar()),

                // Quick Stats
                SliverToBoxAdapter(child: _buildQuickStats()),

                // Folders / Subjects
                SliverToBoxAdapter(child: _buildSubjectChips()),

                // Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: const Text("Recent Lectures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),

                // Notes List
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _notesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)));
                    }

                    var notes = snapshot.data!;
                    // Apply Filters
                    if (_selectedFolderId != -1) notes = notes.where((n) => n['folder_id'] == _selectedFolderId).toList();
                    if (_searchQuery.isNotEmpty) notes = notes.where((n) => n['title'].toString().toLowerCase().contains(_searchQuery)).toList();

                    if (notes.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState());

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildLectureCard(notes[index]),
                        childCount: notes.length,
                      ),
                    );
                  },
                ),

                // Spacer at bottom so content isn't hidden by Floating Button
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),

          // C. FLOATING ACTION BUTTON (Mic)
          
          Positioned(
            bottom: 20, // Adjusted to sit just above the Main Bottom Bar
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordPage())),
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.6), blurRadius: 20, spreadRadius: 0)],
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 32),
              ),
            ),
          ),

          // 4. REMOVED GLASS NAVBAR
          // The navbar is now handled by home_page.dart
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

 Widget _buildOrb(double size, Color color) {
    return ImageFiltered( 
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size, 
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
            stops: const [0.1, 0.6], 
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Profile Placeholder
              Stack(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.backgroundDark, width: 2),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("LUMEN AI", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const Text("Welcome back", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          IconButton(
             onPressed: _pickAndUploadFile, // Quick Upload Access
             icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search knowledge base...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard("Study Streak", "5", "days", Icons.local_fire_department, Colors.orangeAccent)),
          const SizedBox(width: 16),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                final count = snapshot.data?.where((t) => t['is_completed'] == false).length ?? 0;
                return _buildStatCard("Tasks Due", count.toString(), "pending", Icons.assignment_turned_in, Colors.purpleAccent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -5, top: -5,
            child: Icon(icon, color: iconColor.withOpacity(0.2), size: 40),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text(unit, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectChips() {
    return SizedBox(
      height: 60,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _foldersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final folders = snapshot.data!;
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildChip("All", -1),
              ...folders.map((f) => _buildChip(f['name'], f['id'])),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  onPressed: _createFolderDialog,
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryBlue),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, int id) {
    final isSelected = _selectedFolderId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFolderId = id),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.white.withOpacity(0.1)),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4), blurRadius: 15)] : [],
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _buildLectureCard(Map<String, dynamic> note) {
    final isDone = note['status'] == 'Done';
    // Gradients for variety
    final gradients = [
      [Colors.purpleAccent, Colors.deepPurple],
      [Colors.orangeAccent, Colors.redAccent],
      [Colors.tealAccent, Colors.teal],
    ];
    final grad = gradients[note['id'] % gradients.length];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailsPage(noteId: note['id'], title: note['title']))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [grad[0], grad[1]], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: grad[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.science, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.white.withOpacity(0.5), size: 14),
                      const SizedBox(width: 4),
                      Text(isDone ? "Ready" : "Processing...", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            // Status Tag
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDone ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    isDone ? "DONE" : "WAIT",
                    style: TextStyle(color: isDone ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.description_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 10),
          Text("No notes found", style: TextStyle(color: Colors.white.withOpacity(0.3))),
        ],
      ),
    );
  }
}