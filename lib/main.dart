import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'user_data_provider.dart';
import 'splash_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize SharedPreferences early to avoid delays
    final prefs = await SharedPreferences.getInstance();

    // Initialize local notifications
    await NotificationService.initialize();

    // Optionally schedule a daily reminder (if enabled)
    final reminderEnabled = prefs.getBool('reminder_enabled') ?? true;
    if (reminderEnabled) {
      await NotificationService.scheduleDailyReminder();
    }
  } catch (e) {
    print("Startup error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
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
        final accent = themeProvider.accentColor;

        return MaterialApp(
          title: 'Diary App',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: accent,
            cardColor: accent,
            appBarTheme: AppBarTheme(
              backgroundColor: accent,
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
              surface: accent,
              onSurface: Colors.black87,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: accent,
            cardColor: accent,
            appBarTheme: AppBarTheme(
              backgroundColor: accent,
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
              surface: accent,
              onSurface: Colors.white70,
            ),
          ),
          home: SplashPage(toggleTheme: themeProvider.toggleTheme),
        );
      },
    );
  }
}
