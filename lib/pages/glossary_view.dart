import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class GlossaryView extends StatefulWidget {
  const GlossaryView({super.key});

  @override
  State<GlossaryView> createState() => _GlossaryViewState();
}

class _GlossaryViewState extends State<GlossaryView> {
  String _searchQuery = "";

  // Fetch all flashcards, ordered alphabetically by the term ('front')
  final _glossaryStream = Supabase.instance.client
      .from('flashcards')
      .stream(primaryKey: ['id'])
      .order('front', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Global Glossary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -50, right: -50,
            child: _buildOrb(200, Colors.blue.withOpacity(0.1)),
          ),
          
          Column(
            children: [
              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                      hintText: "Search your knowledge base...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // 2. The List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _glossaryStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                    }

                    final allCards = snapshot.data!;
                    
                    // Filter locally based on search
                    final filteredCards = allCards.where((card) {
                      final term = (card['front'] ?? "").toString().toLowerCase();
                      return term.contains(_searchQuery);
                    }).toList();

                    if (filteredCards.isEmpty) {
                      return Center(
                        child: Text("No terms found", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = filteredCards[index];
                        final term = card['front'] ?? "Unknown";
                        final def = card['back'] ?? "No definition";
                        
                        // Logic to show Header (A, B, C...)
                        final firstLetter = term.isNotEmpty ? term[0].toUpperCase() : "#";
                        bool showHeader = false;
                        if (index == 0) {
                          showHeader = true;
                        } else {
                          final prevTerm = filteredCards[index - 1]['front'] ?? "";
                          if (prevTerm.isNotEmpty && prevTerm[0].toUpperCase() != firstLetter) {
                            showHeader = true;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader)
                              Padding(
                                padding: const EdgeInsets.only(top: 24, bottom: 12),
                                child: Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    color: AppTheme.primaryBlue, 
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            
                            _buildTermCard(term, def),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermCard(String term, String def) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.primaryBlue,
          collapsedIconColor: Colors.white54,
          title: Text(
            term,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  def,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
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
}