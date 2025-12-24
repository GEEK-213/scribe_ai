import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'dashboard_view.dart'; // Adjust import based on your project structure

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // --- AUTH LOGIC ---

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted && response.user != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardView()));
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError("An unexpected error occurred");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted && response.user != null) {
        _showSuccess("Account created! Please check your email to confirm.");
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError("Signup failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Dark
      body: Stack(
        children: [
          // 1. AMBIENT GLOW (Orbs)
          Positioned(
            top: -100, left: -100,
            child: _buildOrb(500, const Color(0xFF256AF4).withOpacity(0.3)), // Primary Blue
          ),
          Positioned(
            bottom: -100, right: -100,
            child: _buildOrb(450, Colors.purple.withOpacity(0.2)), // Purple
          ),

          // 2. CENTER CONTENT
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO AREA ---
                  _buildLogo(),
                  const SizedBox(height: 40),

                  // --- GLASS CARD FORM ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50, offset: const Offset(0, 25))],
                        ),
                        child: Column(
                          children: [
                            // Email Input
                            _buildGlassInput(
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              hint: "Email or Username",
                            ),
                            const SizedBox(height: 20),
                            
                            // Password Input
                            _buildGlassInput(
                              controller: _passwordController,
                              icon: Icons.lock_outline,
                              hint: "Password",
                              isPassword: true,
                            ),
                            
                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {}, // Add logic later
                                child: Text("Forgot Password?", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                              ),
                            ),
                            
                            const SizedBox(height: 20),

                            // ACTIONS
                            _isLoading 
                              ? const CircularProgressIndicator(color: Color(0xFF256AF4))
                              : Column(
                                  children: [
                                    // Login Button (Neon Gradient)
                                    _buildNeonButton(
                                      label: "Login",
                                      icon: Icons.arrow_forward,
                                      onTap: _signIn,
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Signup Button (Transparent)
                                    _buildOutlineButton(
                                      label: "Create Account",
                                      onTap: _signUp,
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- SOCIAL LOGIN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 1, width: 60, color: Colors.white.withOpacity(0.1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("OR CONTINUE WITH", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 1.5)),
                      ),
                      Container(height: 1, width: 60, color: Colors.white.withOpacity(0.1)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(Icons.g_mobiledata), // Placeholder for Google
                      const SizedBox(width: 16),
                      _buildSocialButton(Icons.apple), // Placeholder for Apple
                    ],
                  ),

                  const SizedBox(height: 40),
                  
                  // Footer
                  Text(
                    "By continuing, you agree to Lumen AI's Terms & Privacy Policy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.0)]),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: const Color(0xFF256AF4).withOpacity(0.2), blurRadius: 30)],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          "Lumen AI",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
        ),
        Text(
          "Welcome to the future of chat.",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && !_isPasswordVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white.withOpacity(0.4), size: 20),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            )
        ],
      ),
    );
  }

  Widget _buildNeonButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF256AF4), Color(0xFF00D4FF)]), // Neon Gradient
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF256AF4).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          foregroundColor: Colors.white,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.8)),
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
}