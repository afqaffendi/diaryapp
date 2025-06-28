import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) {

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Use the theme toggle on Home Page")),
              );
            },
            title: const Text("Dark Mode"),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text("App Version"),
            subtitle: Text("v1.0.0"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text("Reset Data"),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirm Reset"),
                  content: const Text("Are you sure you want to delete all diary entries?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);

                      },
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
