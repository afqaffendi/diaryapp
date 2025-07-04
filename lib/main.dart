import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme_provider.dart';
import 'user_data_provider.dart';
import 'splash_page.dart';
import 'lock_screen.dart';
import 'notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'text_scale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    await NotificationService.initialize();

    if (prefs.getBool('reminder_enabled') ?? true) {
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
        ChangeNotifierProvider(create: (_) => TextScaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _shouldShowLockScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final pinEnabled = prefs.getBool('pin_enabled') ?? false;
    if (!pinEnabled) return false;

    const storage = FlutterSecureStorage();
    final savedPin = await storage.read(key: 'app_pin');
    return savedPin != null && savedPin.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final textScale = Provider.of<TextScaleProvider>(context).scale;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final accent = themeProvider.accentColor;

        return MaterialApp(
          title: 'Diary App',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: textScale),
              child: child!,
            );
          },
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
          home: FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              final prefs = snapshot.data!;
              final pinEnabled = prefs.getBool('pin_enabled') ?? false;

              if (pinEnabled) {
                return LockScreen(
                  onUnlock: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SplashPage(
                            toggleTheme: themeProvider.toggleTheme),
                      ),
                    );
                  },
                );
              } else {
                return SplashPage(toggleTheme: themeProvider.toggleTheme);
              }
            },
          ),
        );
      },
    );
  }
}
