import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _username = "";
  final TextEditingController _nameController = TextEditingController();
  int _entryCount = 0;
  String _latestDate = "-";
  String _topMoodName = "happy";

  final Map<String, String> moodGifs = {
    'happy': 'assets/images/happy.gif',
    'sad': 'assets/images/sad.gif',
    'angry': 'assets/images/angry.gif',
    'anxious': 'assets/images/anxious.gif',
    'neutral': 'assets/images/neutral.gif',
  };

  final Map<String, String> moodQuotes = {
    'happy': 'Keep smiling. Life is beautiful.',
    'sad': 'It’s okay to feel down. Brighter days are coming.',
    'angry': 'Take a deep breath. Peace begins with you.',
    'anxious': 'This too shall pass. Breathe.',
    'neutral': 'You’re on fire. Keep moving.',
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username');
    setState(() {
      _username = name ?? "Guest";
    });
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
      final mood = entry['feeling'].toString().toLowerCase();
      moodCount[mood] = (moodCount[mood] ?? 0) + 1;
    }

    String mostFrequent = '';
    int highestCount = 0;
    moodCount.forEach((mood, count) {
      if (count > highestCount) {
        mostFrequent = mood;
        highestCount = count;
      }
    });

    setState(() {
      _entryCount = diaries.length;
      _topMoodName = mostFrequent.isNotEmpty ? mostFrequent : 'happy';
      _latestDate = diaries.isNotEmpty
          ? diaries.last['createdAt'].toString().split('T').first
          : "-";
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final directory = await getApplicationDocumentsDirectory();
      final savedImage =
          await File(picked.path).copy('${directory.path}/profile.png');
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
        title: Text("Edit Name", style: GoogleFonts.quicksand(fontSize: 20)),
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
              backgroundColor: const Color(0xFFF1B1E21),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                await prefs.setString('username', newName);
                setState(() {
                  _username = newName;
                });
              }
              Navigator.pop(context);
            },
            child: Text("Save",
                style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Profile",
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
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
                              : const AssetImage("assets/images/profile.jpeg")
                                  as ImageProvider,
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[800],
                            child: const Icon(Icons.edit,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_username,
                        style: GoogleFonts.quicksand(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("Tap to edit",
                        style: GoogleFonts.quicksand(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoTile("Total Diary Entries", "$_entryCount"),
              _buildInfoTile("Latest Entry", _latestDate),
              const SizedBox(height: 30),
              _buildMoodDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFFDAD4CF)
                  : const Color(0xFF1B1E21),
              width: 2.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.quicksand(fontSize: 16)),
              Text(value,
                  style: GoogleFonts.quicksand(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodDisplay() {
    final theme = Theme.of(context);
    final gifPath = moodGifs[_topMoodName] ?? 'assets/images/happy.gif';
    final quote = moodQuotes[_topMoodName] ?? '';
    final textColor = theme.textTheme.bodyMedium?.color;

    return Column(
      children: [
        Text("Most Frequent Mood",
            style: GoogleFonts.quicksand(
                fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(gifPath, height: 140, fit: BoxFit.cover),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Text(
                quote,
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: textColor?.withOpacity(0.75),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
