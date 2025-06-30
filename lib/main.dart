import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'user_data_provider.dart'; // <-- Added
import 'splash_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()), // <-- Added
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Diary App',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: themeProvider.accentColor,
            cardColor: themeProvider.accentColor,
            appBarTheme: AppBarTheme(
              backgroundColor: themeProvider.accentColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            textTheme: GoogleFonts.quicksandTextTheme(),
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: themeProvider.accentColor,
              onSurface: Colors.black87,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: themeProvider.accentColor,
            cardColor: themeProvider.accentColor,
            appBarTheme: AppBarTheme(
              backgroundColor: themeProvider.accentColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            textTheme: GoogleFonts.quicksandTextTheme(
              ThemeData.dark().textTheme,
            ),
            colorScheme: ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: themeProvider.accentColor,
              onSurface: Colors.white70,
            ),
          ),
          home: SplashPage(toggleTheme: themeProvider.toggleTheme),
        );
      },
    );
  }
}
