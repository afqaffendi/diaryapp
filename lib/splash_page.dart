import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const SplashPage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasName = prefs.containsKey('username');
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    hasName ? _goToHome() : _showNameDialog();
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(toggleTheme: widget.toggleTheme)),
    );
  }

  void _showNameDialog() {
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Welcome!", style: GoogleFonts.playfairDisplay(fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("What should we call you?", style: GoogleFonts.quicksand(fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: "Enter your name"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;
              _saveNameAndContinue(_nameController.text.trim());
            },
            child: Text("Let's Go", style: GoogleFonts.quicksand()),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNameAndContinue(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    if (!mounted) return;
    Navigator.pop(context);
    _goToHome();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F5);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/splash.json',
                  height: 280,
                  width: 280,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  "Welcome back, friend",
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Cozy Lottie loading animation
                Lottie.asset(
                  'assets/lottie/loading_paw.json', // Make sure this file exists
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
