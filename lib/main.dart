import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scribe_ai/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await Supabase.initialize(
    url: 'https://espzwnaoigfljqppsiqr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzcHp3bmFvaWdmbGpxcHBzaXFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5Njc0NzcsImV4cCI6MjA4MTU0MzQ3N30.urlESYFqXLXtleaBD6WWvbyBhZ5JXFR06qR9HUscMLA',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScribeAI',
      theme: ThemeData(primarySwatch: Colors.blue),
      
      home: const LoginPage(), 
    );
  }
}