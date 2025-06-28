import 'package:flutter/material.dart';
import 'sql_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = "Afiq Affendi";
  final TextEditingController _nameController = TextEditingController();
  int _entryCount = 0;
  String _topMood = "🥰";
  String _latestDate = "-";

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final diaries = await SQLHelper.getDiaries();
    final moodCount = <String, int>{};

    for (var entry in diaries) {
      moodCount[entry['feeling']] = (moodCount[entry['feeling']] ?? 0) + 1;
    }

    String mostFrequentMood = moodCount.entries
        .fold('', (prev, e) => e.value > (moodCount[prev] ?? 0) ? e.key : prev);

    setState(() {
      _entryCount = diaries.length;
      _topMood = mostFrequentMood;
      _latestDate = diaries.isNotEmpty
          ? diaries.last['createdAt'].toString().split('T').first
          : "-";
    });
  }

  void _editNameDialog() {
    _nameController.text = _username;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Enter your name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _username = _nameController.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _editNameDialog,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage("assets/images/profile.png"), // You can customize this
                  ),
                  const SizedBox(height: 10),
                  Text(_username, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  const Text("Tap to edit", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ListTile(
              title: const Text("Total Diary Entries"),
              trailing: Text("$_entryCount"),
            ),
            ListTile(
              title: const Text("Most Frequent Mood"),
              trailing: Text(_topMood),
            ),
            ListTile(
              title: const Text("Latest Entry"),
              trailing: Text(_latestDate),
            ),
          ],
        ),
      ),
    );
  }
}
