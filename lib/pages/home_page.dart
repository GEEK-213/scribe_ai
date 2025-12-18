import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'dashboard_view.dart';
import 'chat_selection_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // 1. Create the pages once
  final List<Widget> _pages = [
    const DashboardView(),
    const ChatSelectionPage(),
    const Center(child: Text("Study Planner Coming Soon")),
  ];

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: Text(
          _selectedIndex == 0 ? 'ScribeAI Dashboard' : 
          _selectedIndex == 1 ? 'AI Tutor' : 'Planner', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        actions: [IconButton(onPressed: _signOut, icon: const Icon(Icons.logout, color: Colors.white))],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'AI Tutor'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'),
        ],
      ),
      
      // 2. USE INDEXED STACK (Prevents Freezing/Reloading)
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}