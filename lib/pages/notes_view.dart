import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'note_details_page.dart'; 

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final _userId = Supabase.instance.client.auth.currentUser?.id;
  String _searchQuery = "";
  int _selectedFilterIndex = 0; // 0: All, 1: Favorites, 2: AI Summaries

  // --- STREAM ---
  Stream<List<Map<String, dynamic>>> get _notesStream =>
      Supabase.instance.client
          .from('notes')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId ?? '')
          .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENTS (The "Lumen" Glow)
          Positioned(
            top: -100, left: -100,
            child: _buildOrb(400, const Color(0xFF2B8CEE).withOpacity(0.15)), 
          ),
          Positioned(
            bottom: 100, right: -100,
            child: _buildOrb(300, const Color(0xFF2B8CEE).withOpacity(0.08)), 
          ),

          // 2. MAIN CONTENT
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // A. APP BAR
                _buildAppBar(),

                // B. SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildSearchBar(),
                ),

                // C. FILTER CHIPS
                _buildFilterChips(),

                // D. NOTES LIST
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _notesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF2B8CEE)));
                      }

                      var notes = snapshot.data!;
                      
                      // Client-side Search Logic
                      if (_searchQuery.isNotEmpty) {
                        notes = notes.where((n) => n['title'].toString().toLowerCase().contains(_searchQuery)).toList();
                      }
                      
                      // Filter Logic (Example)
                      if (_selectedFilterIndex == 2) { // AI Summaries
                         notes = notes.where((n) => n['status'] == 'Done').toList();
                      }

                      if (notes.isEmpty) return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Padding for FAB
                        physics: const BouncingScrollPhysics(),
                        itemCount: notes.length,
                        itemBuilder: (context, index) => _buildNoteCard(notes[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. FLOATING ACTION BUTTON
          // (Aligned to fit above the HomePage BottomBar)
          Positioned(
            bottom: 20, right: 16,
            child: _buildFAB(),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2B8CEE).withOpacity(0.2), width: 2),
              color: Colors.white10,
            ),
            child: const Icon(Icons.person, color: Colors.white), // Placeholder Avatar
          ),
          const Expanded(
            child: Text(
              "My Notes",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: Color(0xFF9DABB9)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: const InputDecoration(
                hintText: "Search concepts...",
                hintStyle: TextStyle(color: Color(0xFF9DABB9)), 
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["All", "Favorites", "AI Summaries", "Study Guides"];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2B8CEE) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08)),
                boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF2B8CEE).withOpacity(0.2), blurRadius: 10)] : [],
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    // Generate styles based on ID
    final colors = [Colors.blue, Colors.orange, Colors.teal, Colors.pink];
    final icons = [Icons.code, Icons.history_edu, Icons.biotech, Icons.functions];
    final color = colors[note['id'] % colors.length];
    final icon = icons[note['id'] % icons.length];

    return GestureDetector(
      // --- CRITICAL FIX: Pass the full 'note' object, not just ID/Title ---
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (_) => NoteDetailsPage(note: note) 
        )
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Box
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          note['title'] ?? 'Untitled',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text("2h ago", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Tags
                  Row(
                    children: [
                      _tag("Note", color),
                      const SizedBox(width: 6),
                      if (note['status'] == 'Done') _tag("AI Ready", Colors.greenAccent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note['summary'] ?? "Tap to generate summary...", 
                    style: const TextStyle(color: Color(0xFF9DABB9), fontSize: 14, height: 1.5),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF2B8CEE),
      // Link to Record Page or Upload
      onPressed: () {
        // You can link this to your RecordPage
        Navigator.pushNamed(context, '/record'); 
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text("No notes found", style: TextStyle(color: Colors.white.withOpacity(0.3))),
        ],
      ),
    );
  }
}