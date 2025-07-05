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
    debugPrint("Startup error: $e");
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinEnabled = prefs.getBool('pin_enabled') ?? false;

      if (!pinEnabled) return false;

      const storage = FlutterSecureStorage();
      final savedPin = await storage.read(key: 'app_pin');

      return savedPin != null && savedPin.isNotEmpty;
    } catch (e) {
      debugPrint("Lock screen check failed: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = context.watch<TextScaleProvider>().scale;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final accent = themeProvider.accentColor;

        final lightTheme = _buildLightTheme(accent);
        final darkTheme = _buildDarkTheme(accent);

        return AnimatedTheme(
          data: themeProvider.themeMode == ThemeMode.dark ? darkTheme : lightTheme,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: MaterialApp(
            title: 'Diary App',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: lightTheme,
            darkTheme: darkTheme,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: textScale),
                child: child!,
              );
            },
            home: LockScreenGate(
              onUnlocked: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SplashPage(toggleTheme: themeProvider.toggleTheme),
                  ),
                );
              },
              shouldShowLockScreen: _shouldShowLockScreen,
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildLightTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: accent,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: GoogleFonts.quicksand(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      textTheme: GoogleFonts.quicksandTextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ThemeData _buildDarkTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: accent,
        surface: const Color(0xFF121212),
        onSurface: Colors.white70,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: GoogleFonts.quicksand(
          color: Colors.white70,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.black87,
      ),
      textTheme: GoogleFonts.quicksandTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white70,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

class LockScreenGate extends StatefulWidget {
  final Future<bool> Function() shouldShowLockScreen;
  final VoidCallback onUnlocked;

  const LockScreenGate({
    Key? key,
    required this.shouldShowLockScreen,
    required this.onUnlocked,
  }) : super(key: key);

  @override
  State<LockScreenGate> createState() => _LockScreenGateState();
}

class _LockScreenGateState extends State<LockScreenGate> {
  late Future<bool> _lockScreenFuture;

  @override
  void initState() {
    super.initState();
    _lockScreenFuture = widget.shouldShowLockScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _lockScreenFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final shouldShow = snapshot.data!;
        if (shouldShow) {
          return LockScreen(onUnlock: widget.onUnlocked);
        } else {
          return SplashPage(toggleTheme: Provider.of<ThemeProvider>(context, listen: false).toggleTheme);
        }
      },
    );
  }
}
