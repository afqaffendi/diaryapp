import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/profile.jpg'), // Optional
            ),
            const SizedBox(height: 16),
            const Text("User Name", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("user@email.com", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.book),
              title: Text("Total Diary Entries"),
              trailing: Text("24"),
            ),
            const ListTile(
              leading: Icon(Icons.emoji_emotions),
              title: Text("Most Frequent Mood"),
              trailing: Text("🥰 Happy"),
            ),
          ],
        ),
      ),
    );
  }
}
