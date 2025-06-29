import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calendar_page.dart';
import 'sql_helper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomePage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, String> _emojiMap = {
    'happy': '😊',
    'sad': '😢',
    'angry': '😠',
    'anxious': '😰',
    'neutral': '😐',
  };

  String _username = 'Guest';

  String _getMoodEmoji(String feeling) =>
      _emojiMap[feeling.toLowerCase()] ?? '📝';

  Color _getMoodBorderColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFC97B63);
      case 'sad':
        return const Color(0xFF3D5A80);
      case 'angry':
        return const Color.fromARGB(255, 190, 52, 47);
      case 'anxious':
        return const Color(0xFF3D5A80);
      case 'neutral':
        return const Color.fromARGB(255, 104, 102, 109);
      default:
        return Colors.grey;
    }
  }

  Future<String?> _getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profileImagePath');
  }

  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshDiaries();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Guest';
    });
  }

  Future<void> _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CalendarPage(toggleTheme: widget.toggleTheme),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _showForm(int? id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (id != null) {
      final existing = _diaries.firstWhere((e) => e['id'] == id);
      _feelingController.text = existing['feeling'];
      _descriptionController.text = existing['description'];
    } else {
      _feelingController.clear();
      _descriptionController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final borderColor = _getMoodBorderColor(_feelingController.text);

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 70,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Spill your vibes.",
                          style: GoogleFonts.quicksand(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _emojiMap.entries.map((entry) {
                            final selected =
                                _feelingController.text == entry.key;
                            return GestureDetector(
                              onTap: () => setModalState(() {
                                _feelingController.text = entry.key;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFF1B1E21)
                                        : Colors.grey.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  color: selected
                                      ? Colors.grey.withOpacity(0.3)
                                      : Colors.transparent,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: Text(entry.value,
                                      style: const TextStyle(fontSize: 24)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        onChanged: (_) => setModalState(() {}),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write something...',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (_feelingController.text.isEmpty ||
                              _descriptionController.text.isEmpty) {
                            _showErrorSnackbar(
                                modalContext, "Complete both fields");
                            return;
                          }
                          if (id == null) {
                            await SQLHelper.createDiary(
                                _feelingController.text,
                                _descriptionController.text);
                          } else {
                            await SQLHelper.updateDiary(id,
                                _feelingController.text,
                                _descriptionController.text);
                          }
                          _refreshDiaries();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: (_feelingController.text.isNotEmpty &&
                                  _descriptionController.text.isNotEmpty)
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.grey,
                          side: BorderSide(
                            color: (_feelingController.text.isNotEmpty &&
                                    _descriptionController.text.isNotEmpty)
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.grey.withOpacity(0.5),
                            width: 2.5,
                          ),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(18),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.check, size: 24),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 18,
                child: SizedBox(
                  height: 90,
                  child:
                      Image.asset('assets/images/cat.gif', fit: BoxFit.contain),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showErrorSnackbar(BuildContext ctx, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    _refreshDiaries();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        isDark ? Colors.black : const Color(0xFFFFF2CC); // soft beige

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text("Home",
            style: GoogleFonts.playfairDisplay(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<String?>(
              future: _getProfileImagePath(),
              builder: (context, snapshot) {
                final imagePath = snapshot.data;
                final hasImage =
                    imagePath != null && imagePath.trim().isNotEmpty;

                return DrawerHeader(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFFDAD4CF)
                        : const Color(0xFF1B1E21),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: hasImage
                            ? FileImage(File(imagePath!))
                            : const AssetImage("assets/images/profile.png")
                                as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi, $_username!",
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF1B1E21)
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            "Welcome back!",
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFF1B1E21)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text("Profile", style: GoogleFonts.quicksand()),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
                _loadUsername(); // refresh name
                setState(() {}); // refresh image
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text("Settings", style: GoogleFonts.quicksand()),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(toggleTheme: widget.toggleTheme),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diaries.isEmpty
              ? const Center(child: Text("No entries yet."))
              : RefreshIndicator(
                  onRefresh: _refreshDiaries,

                  
                  child: ListView.builder(
                    itemCount: _diaries.length,
                    itemBuilder: (_, index) {
                      final diary = _diaries[index];
                      final time = DateFormat('dd MMM yyyy, hh:mm a')
                          .format(DateTime.parse(diary['createdAt']));
                      final mood = diary['feeling'].toString().toLowerCase();
                      final borderColor = _getMoodBorderColor(mood);

                      return Dismissible(
                        key: Key(diary['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await _deleteDiary(diary['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Entry deleted")),
                          );
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            key: Key("diary-${diary['id']}"),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              border: Border.all(
                                color: borderColor,
                                width: 4.5,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          borderColor.withOpacity(0.15),
                                      child: Text(
                                        _getMoodEmoji(mood),
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        diary['feeling'],
                                        style: GoogleFonts.quicksand(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(time,
                                        style: GoogleFonts.quicksand(
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  diary['description'],
                                  style: GoogleFonts.quicksand(fontSize: 14),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () =>
                                          _showForm(diary['id']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () =>
                                          _deleteDiary(diary['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: SizedBox(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          backgroundColor:
              isDark ? const Color(0xFFFDAD4CF) : const Color(0xFFF1B1E21),
          elevation: 8,
          shape: const CircleBorder(),
          onPressed: () => _showForm(null),
          child: Icon(Icons.add,
              size: 30, color: isDark ? const Color(0xFFF1B1E21) : Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      
      
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomAppBar(
          color: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 10,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(LucideIcons.home,
                      color: _selectedIndex == 0
                          ? selectedColor
                          : Colors.grey),
                  onPressed: () => _onNavTap(0),
                ),
                IconButton(
                  icon: Icon(LucideIcons.calendar,
                      color: _selectedIndex == 1
                          ? selectedColor
                          : Colors.grey),
                  onPressed: () => _onNavTap(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
