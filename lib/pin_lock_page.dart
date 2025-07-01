import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'splash_page.dart';

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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter your PIN", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "PIN",
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPin,
                child: const Text("Unlock"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
