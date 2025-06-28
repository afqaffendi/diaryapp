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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            //logo
            Image.asset(
              'assets/images/logo.png',
              height: 120,
            ),
            const SizedBox(height: 20),
            Text(
              "Dear Diary",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
