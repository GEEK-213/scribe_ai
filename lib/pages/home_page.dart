import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'dashboard_view.dart';
import 'chat_selection_page.dart';


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
  // Using 'final' because the list itself doesn't change, only the selected index changes.
  final List<Widget> _pages = [
    const DashboardView(),        // Index 0: Your Dashboard
    const ChatSelectionPage(),    // Index 1: Your AI Chat Screen
    // Index 2: A placeholder since you haven't built the Planner yet.
    const Center(
      child: Text(
        "Study Planner Coming Soon", 
        style: TextStyle(color: Colors.white), // White text to be visible on dark background
      ),
    ),
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
      // DARK THEME FIX: Sets the background to a dark color like your screenshot.
      backgroundColor: const Color(0xFF121212), 
      
      appBar: AppBar(
        elevation: 0, // Removes the shadow under the app bar for a flat look.
        backgroundColor: const Color(0xFF1E1E1E), // Slightly lighter dark for the bar.
        
        // This logic changes the title text based on which tab is open.
        title: Text(
          _selectedIndex == 0 ? 'ScribeAI Dashboard' : 
          _selectedIndex == 1 ? 'AI Tutor' : 'Planner', 
          style: const TextStyle(
            color: Colors.white, // White text for contrast
            fontWeight: FontWeight.bold
          )
        ),
        
        // The logout button in the top right corner.
        actions: [
          IconButton(
            onPressed: _signOut, 
            icon: const Icon(Icons.logout, color: Colors.white)
          )
        ],
      ),
      
      // The Navigation Bar at the bottom.
      bottomNavigationBar: BottomNavigationBar(
        // DARK THEME FIX: Matches the AppBar color.
        backgroundColor: const Color(0xFF1E1E1E), 
        
        // Tells the bar which icon to highlight.
        currentIndex: _selectedIndex, 
        
        // When tapped, update the state variable to the new index.
        onTap: (index) => setState(() => _selectedIndex = index),
        
        // Styling for the icons.
        selectedItemColor: Colors.blueAccent, // Bright blue for the active tab.
        unselectedItemColor: Colors.grey,     // Grey for inactive tabs.
        
        // This creates the list of buttons at the bottom.
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), 
            label: 'Home'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble), 
            label: 'AI Tutor'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), 
            label: 'Planner'
          ),
        ],
      ),
      
      // IndexedStack is smart: It keeps all pages alive in the background.
      // If you are chatting in 'AI Tutor' and switch tabs, your chat won't disappear.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}