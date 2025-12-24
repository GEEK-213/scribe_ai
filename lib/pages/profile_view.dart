import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _user = Supabase.instance.client.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // HTML 'bg-[#020617]'
      body: Stack(
        children: [
          // 1. BACKGROUND ORBS (Matched to HTML positions)
          Positioned(
            top: -100, left: -100,
            child: _buildOrb(500, Colors.blue.shade900.withOpacity(0.3)),
          ),
          Positioned(
            bottom: -100, right: -100,
            child: _buildOrb(500, Colors.indigo.shade900.withOpacity(0.3)),
          ),
          Positioned(
            top: 100, right: -50,
            child: _buildOrb(300, Colors.cyan.withOpacity(0.15)),
          ),

          // 2. MAIN CONTENT SCROLL
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 80, bottom: 120), // Space for nav bars
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildInterestsSection(),
                  const SizedBox(height: 24),
                  _buildSettingsSection(),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                  Text("Lumen AI v2.4.0 (Build 492)", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),

          // 3. TOP GLASS NAVBAR (Sticky)
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopNavBar(context),
          ),

          // 4. BOTTOM GLASS NAVBAR
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  // --- WIDGET SECTIONS ---

  Widget _buildTopNavBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 15), // Adjust for SafeArea
          decoration: BoxDecoration(
            color: const Color(0xFF050A1E).withOpacity(0.8),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _glassIconButton(Icons.arrow_back, () => Navigator.pop(context)),
              const Text("Profile", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              _glassIconButton(Icons.more_horiz, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              children: [
                // Avatar with Glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blue, Colors.purple]),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 30)],
                      ),
                    ),
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
                        color: Colors.black,
                        image: const DecorationImage(image: NetworkImage("https://i.pravatar.cc/300?img=11"), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                // Name & Role
                const Text("Alex Carter", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Student", style: TextStyle(color: Colors.blue.shade200, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text("Computer Science", style: TextStyle(color: Colors.blue.shade200.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(child: _actionButton("Edit Profile", Icons.edit)),
                    const SizedBox(width: 12),
                    Expanded(child: _actionButton("Share", Icons.share)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Overview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text("View All", style: TextStyle(color: Colors.blue.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statCard("12", "Day Streak", Icons.local_fire_department, Colors.orange, "+2")),
              const SizedBox(width: 12),
              Expanded(child: _statCard("145", "Notes Scribed", Icons.auto_stories, const Color(0xFF10B981), "+15%")),
            ],
          ),
          const SizedBox(height: 12),
          _longStatCard(),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color, String badge) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111928).withOpacity(0.6), // Glass Card
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.2))
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.withOpacity(0.2))),
                    child: Text(badge, style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _longStatCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111928).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.2))
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.purpleAccent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("3,240", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("AI Generations", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Level 8", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80, height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(value: 0.7, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(Colors.blueAccent)),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Interests", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _interestChip("Machine Learning"),
              _interestChip("Data Structures"),
              _interestChip("UX Design"),
              _interestChip("Python"),
              _addInterestButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _interestChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _addInterestButton() {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), style: BorderStyle.solid),
      ),
      child: Icon(Icons.add, color: Colors.white.withOpacity(0.5), size: 16),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Settings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _settingsGroup([
            _settingsTile("Account Details", Icons.person, Colors.blue),
            _settingsTile("Notifications", Icons.notifications, Colors.indigo, badge: "2"),
            _settingsTile("AI Preferences", Icons.tune, Colors.cyan),
          ]),
          const SizedBox(height: 16),
          _settingsGroup([
            _settingsTile("Privacy & Security", Icons.lock, Colors.white60),
            _settingsTile("Help & Support", Icons.help, Colors.white60),
          ]),
        ],
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111928).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _settingsTile(String title, IconData icon, Color color, {String? badge}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.1))),
                child: Icon(icon, color: color == Colors.white60 ? Colors.white70 : color, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 4)]),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login'); // Adjust route
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.withOpacity(0.2))),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 18),
            SizedBox(width: 8),
            Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _glassIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue.shade300, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
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

 Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 85,
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF050A1E).withOpacity(0.8),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [ // Correct property is 'children'
              _navItem(Icons.home_outlined, false),
              _navItem(Icons.folder_open, false),
              const SizedBox(width: 40), // Gap for FAB
              _navItem(Icons.school_outlined, false),
              _navItem(Icons.person, true),
            ],
          ),
        ),
      ),
    );
  }
  
  // Custom FAB Logic handled in Dashboard, this is visual only for Profile
  List<Widget> get items => []; // Placeholder

  Widget _navItem(IconData icon, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? Colors.blueAccent : Colors.white54, size: 26),
        if (isActive) Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle))
      ],
    );
  }
}