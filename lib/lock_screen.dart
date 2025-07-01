import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String _error = '';

  Future<void> _checkPin() async {
    final savedPin = await _storage.read(key: 'user_pin'); // fixed key
    final enteredPin = _pinController.text.trim();

    if (savedPin != null && enteredPin == savedPin.trim()) {
      widget.onUnlock();
    } else {
      setState(() => _error = "Incorrect PIN");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 60, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                "Enter PIN to unlock",
                style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: "Enter your PIN",
                  errorText: _error.isNotEmpty ? _error : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: Text("Unlock"),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await _storage.delete(key: 'user_pin'); // also fix here if needed
                  await _storage.write(key: 'pin_enabled', value: 'false');
                  widget.onUnlock();
                },
                child: Text(
                  "Forgot PIN?",
                  style: GoogleFonts.quicksand(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
