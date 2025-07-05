import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuotesPage extends StatefulWidget {
  const QuotesPage({Key? key}) : super(key: key);

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  String _quote = "Loading...";
  String _author = "";

 Future<void> fetchQuote() async {
  try {
    final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _quote = data[0]['q'];     
        _author = data[0]['a'];  
      });
    } else {
      setState(() {
        _quote = "Failed to fetch quote. Status: ${response.statusCode}";
        _author = "";
      });
    }
  } catch (e) {
    setState(() {
      _quote = "Something went wrong: $e";
      _author = "";
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Quotes",
          style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0),
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
          width: 3.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.format_quote, size: 40, color: Colors.purple),
          const SizedBox(height: 12),
          Text(
            '"$_quote"',
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "- $_author",
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchQuote,
            icon: const Icon(Icons.refresh),
            label: const Text("New Quote"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
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

    );
  }
}
