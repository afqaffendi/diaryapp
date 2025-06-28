import 'package:flutter/material.dart';
import 'sql_helper.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback toggleTheme;

  const SettingsPage({Key? key, required this.toggleTheme}) : super(key: key);

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset All Diaries?"),
        content: const Text("This will delete all diary entries permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final diaries = await SQLHelper.getDiaries();
              for (var entry in diaries) {
                await SQLHelper.deleteDiary(entry['id']);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All entries deleted.")));
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Toggle Light/Dark Theme"),
            trailing: const Icon(Icons.brightness_6),
            onTap: toggleTheme,
          ),
          ListTile(
            title: const Text("Reset All Diary Entries"),
            trailing: const Icon(Icons.delete_forever),
            onTap: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }
}
