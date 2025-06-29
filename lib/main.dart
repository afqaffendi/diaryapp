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
        scaffoldBackgroundColor: Color(0xFFFDAD4CF),
        cardColor: Color(0xFFFDAD4CF),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF1B1E21)),
        iconTheme: const IconThemeData(color:   Color(0xFFF1B1E21)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor:Color(0xFFF1B1E21),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFFF1B1E21),
        cardColor: const  Color(0xFFF1B1E21),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF1B1E21)),
        iconTheme: const IconThemeData(color: Color(0xFFFDAD4CF)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFDAD4CF),
        ),
      ),
      home: SplashPage(toggleTheme: _toggleTheme),
    );
  }
}
