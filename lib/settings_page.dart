import 'package:flutter/material.dart';
import 'sql_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const SettingsPage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _visible = false;

  final List<Color> _colorChoices = [
  Color(0xFFF1B1E21), // Deep Red
  Color(0xFFFDAD4CF), // Soft Peach
  Color(0xFFC97B63),  // Blush Nude
  Color(0xFF3D5A80),  // Ocean Blue
  Color(0xFF6A994E),  // Sage Green
  Color(0xFF9B5DE5),  // Violet Purple
  Color(0xFF212529),  // Dark Grey
  Color(0xFFFFC300),  // Bright Yellow
  Color(0xFFFF6F61),  // Coral Pink
  Color(0xFF00A896),  // Calm Teal
  Color(0xFF4A4E69),  // Dusty Indigo
  Color(0xFFE07A5F),  // Clay Orange
  Color(0xFFF0A6CA),  // Bubblegum Pink
  Color(0xFF7B2CBF),  // Rich Lavender
  Color(0xFF2A9D8F),  // Jungle Green
  Color(0xFFB5838D),  // Faded Rose
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Reset All Diaries?", style: GoogleFonts.quicksand(fontSize: 20)),
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
              backgroundColor: const Color(0xFFF1B1E21),
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

  bool isDarkColor(Color color) {
    return color.computeLuminance() < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final borderColor = isDark ? Colors.white : const Color(0xFF1B1E21);

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
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _visible
            ? ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  _buildCard(
                    context,
                    title: "Toggle Light / Dark Theme",
                    icon: Icons.brightness_6_rounded,
                    onTap: widget.toggleTheme,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    context,
                    title: "Reset All Diary Entries",
                    icon: Icons.delete_forever_rounded,
                    onTap: () => _confirmReset(context),
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Choose Accent Color",
                    style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
  spacing: 12,
  runSpacing: 12,
  children: _colorChoices.map((color) {
    final isSelected = themeProvider.accentColor.value == color.value;
    final contrastBorder = color.computeLuminance() < 0.5 ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () => themeProvider.setAccentColor(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? contrastBorder.withOpacity(0.8)
                : contrastBorder.withOpacity(0.3),
            width: isSelected ? 3.2 : 1.2,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check, color: contrastBorder, size: 20)
            : null,
      ),
    );
  }).toList(),
),

                ],
              )
            : const SizedBox(),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withOpacity(0.6), width: 3.2),
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: Icon(icon, size: 24, color: iconColor ?? Theme.of(context).iconTheme.color),
        onTap: onTap,
      ),
    );
  }
}
