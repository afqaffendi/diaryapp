import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'splash_page.dart';
import 'package:google_fonts/google_fonts.dart';

class PinLockPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const PinLockPage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage> {
  final _pinController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String? _error;

  Future<void> _checkPin() async {
    final storedPin = await _storage.read(key: 'user_pin');
    if (_pinController.text == storedPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SplashPage(toggleTheme: widget.toggleTheme),
        ),
      );
    } else {
      setState(() {
        _error = "Incorrect PIN";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "Enter your PIN",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                autofocus: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(fontSize: 20, letterSpacing: 6),
                decoration: InputDecoration(
                  hintText: "● ● ● ● ● ●",
                  counterText: "",
                  errorText: _error,
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _checkPin,
                icon: const Icon(Icons.login),
                label: const Text("Unlock"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
