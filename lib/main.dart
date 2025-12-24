import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_view.dart'; 
import 'pages/chat_selection_page.dart';
import 'pages/profile_view.dart';
import 'pages/home_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://espzwnaoigfljqppsiqr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzcHp3bmFvaWdmbGpxcHBzaXFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5Njc0NzcsImV4cCI6MjA4MTU0MzQ3N30.urlESYFqXLXtleaBD6WWvbyBhZ5JXFR06qR9HUscMLA',
  );

  runApp(const LumenApp());
}

class LumenApp extends StatelessWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumen',
      debugShowCheckedModeBanner: false, 
      theme: AppTheme.darkTheme, 
      
      // Check if user is logged in
      home: Supabase.instance.client.auth.currentUser == null
          ? const LoginPage()
          : const HomePage(), 
    );
  }
}