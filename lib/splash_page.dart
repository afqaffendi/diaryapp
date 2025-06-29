import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const SplashPage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasName = prefs.containsKey('username');

    await Future.delayed(const Duration(seconds: 2));

    if (!hasName) {
      _showNameDialog();
    } else {
      _goToHome();
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(toggleTheme: widget.toggleTheme),
      ),
    );
  }

  void _showNameDialog() {
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    Navigator.pop(context); // close dialog
    _goToHome();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.gif', height: 420, width: 460),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
