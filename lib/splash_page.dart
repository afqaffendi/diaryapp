import 'package:flutter/material.dart';
import 'dart:async';
import 'homepage.dart';

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

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(toggleTheme: widget.toggleTheme),
        ),
      );
    });
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
            // Logo
            Image.asset(
              'assets/images/logo.gif',
              height: 420,
              width: 460,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
