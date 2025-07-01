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
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomePage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _showExtraMoods = false; 

  List<Map<String, dynamic>> _diaries = [];
  List<Map<String, dynamic>> _filteredDiaries = [];
  Set<int> _expandedCardIds = {};

  String _username = 'Guest';
  String? _profileImagePath;
  bool _isLoading = true;
  int _selectedIndex = 0;

  final Map<String, String> _emojiMap = {
    'happy': '😊',
    'sad': '😢',
    'angry': '😠',
    'anxious': '😰',
    'neutral': '😐',
  };
  final List<String> _extraEmojis = ['😎', '😴', '🤯', '😇', '🤗', '🥳', '🤔', '🤫', '❤️'];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _refreshDiaries();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Guest';
      _profileImagePath = prefs.getString('profileImagePath');
    });
  }

Future<void> _refreshDiaries() async {
  final data = await SQLHelper.getDiaries();
  setState(() {
    _diaries = data;
    _filterDiaries(_searchController.text); // apply search after refresh
    _isLoading = false;
  });
}


void _filterDiaries(String query) {
  final lowerQuery = query.toLowerCase();

  final filtered = _diaries.where((entry) {
    final desc = entry['description'].toString().toLowerCase();
    final mood = entry['feeling'].toString().toLowerCase();
    final emoji = _getMoodEmoji(mood).toLowerCase();
    final createdAt = DateFormat('dd MMM yyyy')
        .format(DateTime.parse(entry['createdAt']))
        .toLowerCase();

    return desc.contains(lowerQuery) ||
           mood.contains(lowerQuery) ||
           emoji.contains(lowerQuery) ||
           createdAt.contains(lowerQuery);
  }).toList();

  setState(() => _filteredDiaries = filtered);
}


  int _calculateStreak() {
    final now = DateTime.now();
    final entryDates = _diaries.map((e) => DateFormat('yyyy-MM-dd')
        .format(DateTime.parse(e['createdAt']))).toSet();

    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final formatted = DateFormat('yyyy-MM-dd').format(date);
      if (entryDates.contains(formatted)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CalendarPage(toggleTheme: widget.toggleTheme),
      ));
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Color _getMoodBorderColor(BuildContext context, String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return const Color(0xFFC97B63);
      case 'sad':
      case 'anxious': return const Color.fromARGB(255, 30, 45, 64);
      case 'angry': return const Color.fromARGB(255, 190, 52, 47);
      case 'neutral': return const Color.fromARGB(255, 104, 102, 109);
      default: return Theme.of(context).colorScheme.outline;
    }
  }

  String _getMoodEmoji(String feeling) => _emojiMap[feeling.toLowerCase()] ?? '📝';

  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    _refreshDiaries();
  }

@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final selectedColor = isDark ? const Color(0xFF1B1E21) : const Color(0xFFFDAD4CF);

  return Scaffold(
    drawer: _buildDrawer(isDark),
    appBar: _buildAppBar(),

    bottomNavigationBar: _buildBottomNavBar(isDark, selectedColor),
    body: Column(
  children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search your diary...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        onChanged: _filterDiaries,
      ),
    ),
    _buildStreakWidget(),
    Expanded(child: _buildDiaryList()),
  ],
),

  );
}



Widget _buildMoodPicker(Function setModalState) {
  return SizedBox(
    height: 80,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: _emojiMap.entries.map((entry) {
        final selected = _feelingController.text == entry.key;
        return GestureDetector(
          onTap: () => setModalState(() {
            _feelingController.text = entry.key;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
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
              child: Text(entry.value, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      }).toList(),
    ),
  );
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
      builder: (modalContext, setModalState) => Stack(
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
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    id == null ? "Spill your vibes." : "Edit your vibes.",
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMoodPicker(setModalState),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
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
                      final feeling = _feelingController.text.trim();
                      final desc = _descriptionController.text.trim();
                      if (feeling.isEmpty || desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Complete both fields")),
                        );
                        return;
                      }

                      if (id == null) {
                        await SQLHelper.createDiary(feeling, desc, DateTime.now());
                      } else {
                        await SQLHelper.updateDiary(id, feeling, desc);
                      }

                      Navigator.pop(context);
                      _refreshDiaries();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFFFDAD4CF)
                          : const Color(0xFFF1B1E21),
                      foregroundColor:
                          isDark ? Colors.black : Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(18),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.check),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 18,
            child: SizedBox(
              height: 90,
              child: Image.asset(
                'assets/images/cat.gif', // make sure this exists
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}




  Widget _buildDiaryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_filteredDiaries.isEmpty) {
      return const Center(child: Text("No entries yet."));
    } else {
      return RefreshIndicator(
        onRefresh: _refreshDiaries,
        child: ListView.builder(
          itemCount: _filteredDiaries.length,
          padding: const EdgeInsets.only(bottom: 80),
          itemBuilder: (_, index) {
            final diary = _filteredDiaries[index];
            final time = DateFormat('dd MMM yyyy, hh:mm a')
                .format(DateTime.parse(diary['createdAt']));
            final mood = diary['feeling'].toString().toLowerCase();
            final borderColor = _getMoodBorderColor(context, mood);
            final isExpanded = _expandedCardIds.contains(diary['id']);
            return _buildDiaryCard(diary, time, borderColor, isExpanded);
          },
        ),
      );
    }
  }

Widget _buildDiaryCard(Map<String, dynamic> diary, String time, Color borderColor, bool isExpanded) {
  final id = diary['id'];
  return Dismissible(
    key: Key(id.toString()),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.redAccent,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (_) async {
      await _deleteDiary(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry deleted")),
      );
      return true;
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: borderColor, width: 4.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: borderColor.withOpacity(0.2),
                child: Text(
                  _getMoodEmoji(diary['feeling']),
                  style: const TextStyle(fontSize: 18),
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
              Text(
                time,
                style: GoogleFonts.quicksand(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            diary['description'],
            style: GoogleFonts.quicksand(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: "Edit",
                onPressed: () => _showForm(id),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                tooltip: "Delete",
                onPressed: () async {
                  await _deleteDiary(id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Entry deleted")),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}




  Widget _buildStreakWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final streak = _calculateStreak();
    final message = streak > 0
        ? " $streak-day streak!"
        : "No streak yet. Let's start today!";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
          width: 3.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: Lottie.asset(
              streak > 0
                  ? 'assets/lottie/streak.json'
                  : 'assets/lottie/idlecat.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
    );
  }

Widget _buildBottomNavBar(bool isDark, Color selectedColor) {
  final Color navBarColor = isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21);
  final Color iconColor = isDark ? const Color(0xFF1B1E21) : Colors.white;
  final Color inactiveColor = isDark ? const Color(0xFF5C5C5C) : Colors.grey[400]!;

  return Container(
    margin: const EdgeInsets.all(16),
    height: 70,
    decoration: BoxDecoration(
      color: navBarColor,
      borderRadius: BorderRadius.circular(40),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(LucideIcons.home, size: 26),
          color: _selectedIndex == 0 ? iconColor : inactiveColor,
          onPressed: () => _onNavTap(0),
        ),
        IconButton(
          icon: const Icon(LucideIcons.plus, size: 26),
          color: iconColor,
          onPressed: () => _showForm(null),
        ),
        IconButton(
          icon: const Icon(LucideIcons.calendarDays, size: 26),
          color: _selectedIndex == 1 ? iconColor : inactiveColor,
          onPressed: () => _onNavTap(1),
        ),
      ],
    ),
  );
}


Widget _buildNavItem({
  required IconData icon,
  required int index,
  required Color selectedColor,
  required Color unselectedColor,
  required Function(int) onTap,
}) {
  return IconButton(
    icon: Icon(icon, size: 26),
    onPressed: () => onTap(index),
    color: _selectedIndex == index ? selectedColor : unselectedColor,
  );
}

Widget _buildAddButton(Color color) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: IconButton(
      icon: const Icon(LucideIcons.plus, size: 24),
      color: Colors.white,
      onPressed: () => _showForm(null),
    ),
  );
}











  Drawer _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _profileImagePath != null &&
                      File(_profileImagePath!).existsSync()
                    ? FileImage(File(_profileImagePath!))
                    : const AssetImage("assets/images/profile.jpeg") as ImageProvider,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hi, $_username!",
                      style: GoogleFonts.quicksand(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF1B1E21) : Colors.white,
                      )),
                    Text("Welcome back!",
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF1B1E21) : Colors.white,
                      )),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text("Profile", style: GoogleFonts.quicksand()),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              _loadUserInfo();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text("Settings", style: GoogleFonts.quicksand()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(toggleTheme: widget.toggleTheme),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}