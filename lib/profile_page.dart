import 'package:flutter/material.dart';
import 'sql_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
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
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/profile.png';
    final file = File(path);

    if (await file.exists()) {
      setState(() {
        _profileImage = file;
      });
    }

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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final directory = await getApplicationDocumentsDirectory();
      final savedImage = await File(picked.path).copy('${directory.path}/profile.png');
      setState(() {
        _profileImage = savedImage;
      });
    }
  }

  void _editNameDialog() {
    _nameController.text = _username;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Edit Name", style: GoogleFonts.playfairDisplay(fontSize: 20)),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Enter your name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.quicksand()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() => _username = _nameController.text);
              Navigator.pop(context);
            },
            child: Text("Save", style: GoogleFonts.quicksand(color: Colors.white)),
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
        title: Text(
          "Profile",
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _editNameDialog,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage("assets/images/profile.png") as ImageProvider,
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.teal,
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _username,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap to edit",
                    style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoTile("Total Diary Entries", "$_entryCount"),
            _buildInfoTile("Most Frequent Mood", _topMood),
            _buildInfoTile("Latest Entry", _latestDate),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        title: Text(title, style: GoogleFonts.quicksand(fontSize: 14)),
        trailing: Text(value, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
