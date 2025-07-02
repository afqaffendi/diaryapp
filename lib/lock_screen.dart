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
  final _storage = const FlutterSecureStorage();
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  String _error = '';

  Future<void> _checkPin() async {
    final savedPin = await _storage.read(key: 'user_pin');
    final enteredPin = _controllers.map((c) => c.text).join();

    if (savedPin != null && enteredPin == savedPin.trim()) {
      widget.onUnlock();
    } else {
      setState(() => _error = "Incorrect PIN");
      _controllers.forEach((c) => c.clear());
      _focusNodes.first.requestFocus();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 60, color: accentColor),
              const SizedBox(height: 20),
              Text(
                "Enter PIN to unlock",
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // 4 digit PIN fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(fontSize: 24),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 3) {
                          _focusNodes[i + 1].requestFocus();
                        } else if (value.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: Text("Unlock"),
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await _storage.delete(key: 'user_pin');
                  await _storage.write(key: 'pin_enabled', value: 'false');
                  widget.onUnlock();
                },
                child: Text(
                  "Forgot PIN?",
                  style: GoogleFonts.quicksand(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
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
