import 'package:flutter/material.dart';
import 'sql_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'secure_storage_helper.dart';
import 'text_scale_provider.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const SettingsPage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isReminderEnabled = true;
  bool _isPinEnabled = false;

  final Map<String, Color> _themeSwatches = {
    'red': Color(0xFFFAD4CF),
    'pink': Color(0xFFFFDDEE),
    'black': Colors.black,
    'blue': Color(0xFFD6E6FF),
  };

  @override
  void initState() {
    super.initState();
    _loadReminderPreference();
    _loadPinStatus();
  }

  void _loadReminderPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReminderEnabled = prefs.getBool('reminder_enabled') ?? true;
    });
  }

  void _toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isReminderEnabled = value);
    await prefs.setBool('reminder_enabled', value);

    value ? await NotificationService.scheduleDailyReminder() : await NotificationService.cancelReminder();
  }

  void _togglePinLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final pin = await _showSetPinDialog(context);
      if (pin != null && pin.length == 4) {
        await SecureStorageHelper.savePin(pin);
        await prefs.setBool('pin_enabled', true);
        setState(() => _isPinEnabled = true);
      } else {
        await prefs.setBool('pin_enabled', false);
        setState(() => _isPinEnabled = false);
      }
    } else {
      await SecureStorageHelper.clearPin();
      await prefs.setBool('pin_enabled', false);
      setState(() => _isPinEnabled = false);
    }
  }

  Future<String?> _showSetPinDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Set 4-digit PIN"),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            hintText: "Enter PIN",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
        ],
      ),
    );
  }

  void _loadPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPinEnabled = prefs.getBool('pin_enabled') ?? false;
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
                SnackBar(content: Text("All entries deleted.", style: GoogleFonts.quicksand())),
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
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final scaleProvider = Provider.of<TextScaleProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : const Color(0xFF1B1E21);
    final bgColor = theme.scaffoldBackgroundColor;

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildCard(context, title: "Toggle Light / Dark Theme", icon: Icons.brightness_6_rounded, onTap: widget.toggleTheme, borderColor: borderColor),
          const SizedBox(height: 16),
          _buildToggleCard(context, title: "Daily Reminder Notification", value: _isReminderEnabled, onChanged: _toggleReminder, borderColor: borderColor),
          const SizedBox(height: 16),
          _buildToggleCard(context, title: "Enable PIN Lock", value: _isPinEnabled, onChanged: _togglePinLock, borderColor: borderColor),
          const SizedBox(height: 16),
          _buildCard(context, title: "Reset All Diary Entries", icon: Icons.delete_forever_rounded, onTap: () => _confirmReset(context), iconColor: Colors.redAccent, textColor: Colors.redAccent, borderColor: borderColor),
          const SizedBox(height: 24),
          Text("Choose Accent Theme", style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _themeSwatches.entries.map((entry) {
              final themeName = entry.key;
              final color = entry.value;
              final isSelected = themeProvider.selectedTheme == themeName;
              final contrast = color.computeLuminance() < 0.5 ? Colors.white : Colors.black;

              return GestureDetector(
                onTap: () => themeProvider.setThemeByName(themeName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? contrast.withOpacity(0.9) : contrast.withOpacity(0.3),
                      width: isSelected ? 3.2 : 1.2,
                    ),
                  ),
                  child: isSelected ? Icon(Icons.check, color: contrast, size: 20) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text("Adjust Text Size", style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold)),
          Slider(
            value: scaleProvider.scale,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: "${(scaleProvider.scale * 100).round()}%",
            onChanged: (value) => scaleProvider.setScale(value),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {
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
          style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color),
        ),
        trailing: Icon(icon, size: 24, color: iconColor ?? Theme.of(context).iconTheme.color),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleCard(BuildContext context, {
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withOpacity(0.6), width: 3.2),
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
      ),
      child: SwitchListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          title,
          style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
