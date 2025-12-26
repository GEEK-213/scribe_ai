import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'dashboard_view.dart';
import 'chat_selection_page.dart';
import 'profile_view.dart';
import 'planner_page.dart'; 

// We use a StatefulWidget because the UI needs to change when we tap the bottom bar.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variable to keep track of which tab is currently selected (0 = First tab).
  int _selectedIndex = 0;

  // This list holds the actual screens that will show up in the body.

  final List<Widget> _pages = [
    const DashboardView(),       
    const ChatSelectionPage(),
    const PlannerPage(),
    const ProfileView(),
  ];

  // Function to handle logging out from Supabase.
  Future<void> _signOut() async {
    // 1. Tell Supabase to sign the user out.
    await Supabase.instance.client.auth.signOut();
    
    // 2. Check if the widget is still on screen (good practice in async functions).
    if (mounted) {
      // 3. Remove this screen and replace it with the Login Page.
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: const Color(0xFF121212), 
      
     appBar: null,
      
     bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E), 
        currentIndex: _selectedIndex, 
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blueAccent, 
        unselectedItemColor: Colors.grey,
        
        type: BottomNavigationBarType.fixed, 
        
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'AI Tutor'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}