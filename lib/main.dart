import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the connection to Supabase
  // REPLACE THESE WITH YOUR KEYS FROM STEP 3
  await Supabase.initialize(
    url: 'YOUR_PROJECT_URL_HERE',
    anonKey: 'YOUR_ANON_PUBLIC_KEY_HERE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScribeAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('ScribeAI: Connection Successful!'),
        ),
      ),
    );
  }
}