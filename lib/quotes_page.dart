import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class QuotesPage extends StatefulWidget {
  const QuotesPage({Key? key}) : super(key: key);

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  String _quote = "";
  String _author = "";
  bool _isLoading = true;

  Future<void> fetchQuote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _quote = data[0]['q'];
          _author = data[0]['a'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _quote = "Could not fetch quote. Try again later.";
          _author = "";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _quote = "Oops! Something went wrong.";
        _author = "";
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchQuote();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Daily Quote",
          style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            child: _isLoading
                ? Column(
                    key: const ValueKey("loading"),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset("assets/lottie/quotes.json", height: 120),
                      const SizedBox(height: 20),
                      Text(
                        "Fetching a quote...",
                        style: GoogleFonts.quicksand(fontSize: 20),
                      ),
                    ],
                  )
                : Container(
                    key: const ValueKey("quote"),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.format_quote_rounded, size: 40, color: Colors.purple),
                        const SizedBox(height: 12),
                        Text(
                          '"$_quote"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _author.isNotEmpty ? "- $_author" : "- Unknown",
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: fetchQuote,
                          icon: const Icon(Icons.refresh),
                          label: const Text("New Quote"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: borderColor,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
