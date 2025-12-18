import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Controllers to capture what the user types
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 2. Loading state (to show a spinner while waiting for Supabase)
  bool _isLoading = false;

  // 3. The Login Function
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Logic: Ask Supabase to sign in
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on AuthException catch (error) {
      // Logic: If Supabase says "Wrong password", tell the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error occurred'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 4. The Sign Up Function
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Logic: Create a new user in Supabase
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please Log in.')),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ScribeAI Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email Input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            // Password Input
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true, // Hides the password
            ),
            const SizedBox(height: 24),
            // Buttons
            _isLoading
                ? const CircularProgressIndicator() 
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _signIn,
                        child: const Text('Log In'),
                      ),
                      TextButton(
                        onPressed: _signUp,
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}