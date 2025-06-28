import 'package:flutter/material.dart';
import 'splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFEBFFF5),
        cardColor: const Color(0xFFF8E8E9),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF8E8E9)),
        iconTheme: const IconThemeData(color: Color(0xFF7CAE9E)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFEC0B3),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1F2A26),
        cardColor: const Color(0xFF3A3B3C),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF3A3B3C)),
        iconTheme: const IconThemeData(color: Color(0xFFA3D7CA)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD29C91),
        ),
      ),
      home: SplashPage(toggleTheme: _toggleTheme),
    );
  }
}
