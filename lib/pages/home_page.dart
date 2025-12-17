import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'record_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // This is a list of your subjects. Later we will fetch this from the database.
  final List<String> subjects = [
    'Mobile App Dev (CSA-305)',
    'Cyber Security (CSA-304)',
    'Machine Learning (CSA-306)',
    'Full Stack Dev',
  ];

  // Function to Log Out
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      // Go back to Login Page
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          // Logout Button
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      // The Body: A List of Subjects
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: Text(subjects[index]), // Shows the subject name
              subtitle: const Text('0 Lectures'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // We will add navigation here later
                print('Tapped on ${subjects[index]}');
              },
            ),
          );
        },
      ),
      // The Record Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to the Record Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecordPage()),
          );
        },
        label: const Text('New Lecture'),
        icon: const Icon(Icons.mic),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}