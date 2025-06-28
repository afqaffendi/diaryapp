import 'package:flutter/material.dart';
import 'sql_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback toggleTheme;

  const SettingsPage({Key? key, required this.toggleTheme}) : super(key: key);

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Reset All Diaries?", style: GoogleFonts.playfairDisplay(fontSize: 20)),
        content: Text(
          "This will delete all diary entries permanently.",
          style: GoogleFonts.quicksand(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.quicksand()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final diaries = await SQLHelper.getDiaries();
              for (var entry in diaries) {
                await SQLHelper.deleteDiary(entry['id']);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("All entries deleted.", style: GoogleFonts.quicksand()),
                ),
              );
            },
            child: Text("Confirm", style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Settings",
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(
                "Toggle Light/Dark Theme",
                style: GoogleFonts.quicksand(fontSize: 15),
              ),
              trailing: const Icon(Icons.brightness_6),
              onTap: toggleTheme,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(
                "Reset All Diary Entries",
                style: GoogleFonts.quicksand(fontSize: 15, color: Colors.redAccent),
              ),
              trailing: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onTap: () => _confirmReset(context),
            ),
          ),
        ],
      ),
    );
  }
}
