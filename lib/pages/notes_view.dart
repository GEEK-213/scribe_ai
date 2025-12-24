import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'note_details_page.dart'; // Ensure this import exists

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
      backgroundColor: const Color(0xFF101922), // HTML 'bg-[#101922]'
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENTS (The "Lumen" Glow)
          Positioned(
            top: -100, left: -100,
            child: _buildOrb(400, const Color(0xFF2B8CEE).withOpacity(0.15)), // Primary Blue
          ),
          Positioned(
            bottom: 100, right: -100,
            child: _buildOrb(300, const Color(0xFF2B8CEE).withOpacity(0.08)), // Subtle Glow
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
                      // Filter Logic
                      if (_searchQuery.isNotEmpty) {
                        notes = notes.where((n) => n['title'].toString().toLowerCase().contains(_searchQuery)).toList();
                      }
                      // (Add Favorite/AI logic here later based on your DB columns)

                      if (notes.isEmpty) return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), // Bottom pad for Nav/FAB
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
          Positioned(
            bottom: 100, right: 16,
            child: _buildFAB(),
          ),

          // 4. BOTTOM NAV (Reusing the design from Profile/Dashboard)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomNav(),
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
              image: const DecorationImage(image: NetworkImage("https://i.pravatar.cc/150?img=12"), fit: BoxFit.cover),
            ),
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
        color: Colors.black.withOpacity(0.2), // .glass-input
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
                hintStyle: TextStyle(color: Color(0xFF9DABB9)), // Muted text
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: const Icon(Icons.tune, color: Color(0xFF2B8CEE), size: 20),
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
              child: Row(
                children: [
                  if (filters[index] == "AI Summaries") ...[
                    Icon(Icons.auto_awesome, size: 16, color: isSelected ? Colors.white : const Color(0xFF2B8CEE)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    filters[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    // Generate styles based on ID (to mimic your HTML variety)
    final colors = [Colors.blue, Colors.orange, Colors.teal, Colors.pink];
    final icons = [Icons.code, Icons.history_edu, Icons.biotech, Icons.functions];
    final color = colors[note['id'] % colors.length];
    final icon = icons[note['id'] % icons.length];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailsPage(noteId: note['id'], title: note['title']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03), // .glass-panel
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
                      if (note['status'] == 'Done') _tag("AI Summary", Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note['summary'] ?? "No summary available yet. Tap to generate one with AI.", // Fallback text
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
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2B8CEE),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: const Color(0xFF2B8CEE).withOpacity(0.5), blurRadius: 20)], // .fab-glow
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
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

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: const Color(0xFF101922).withOpacity(0.8), // Glass Nav Background
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.home_outlined, "Home", false),
              _navItem(Icons.description, "Notes", true), // Active State
              const SizedBox(width: 40), // Gap
              _navItem(Icons.folder_open, "Library", false),
              _navItem(Icons.person_outline, "Profile", false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF2B8CEE) : Colors.white54, size: 26),
            if (isActive)
              Positioned(
                top: -2, right: -2,
                child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF2B8CEE), shape: BoxShape.circle)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: isActive ? const Color(0xFF2B8CEE) : Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}