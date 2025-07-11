import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calendar_page.dart';
import 'sql_helper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'quotes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';

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

  List<Map<String, dynamic>> _diaries = [];
  List<Map<String, dynamic>> _filteredDiaries = [];
  Set<int> _expandedCardIds = {};

Future<File?> _loadProfileImage() async {
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/profile.png';
  final file = File(path);
  return file.existsSync() ? file : null;
}

Future<void> _toggleFavorite(int id, bool isCurrentlyFavorite) async {
  await SQLHelper.toggleFavorite(id, !isCurrentlyFavorite);
  _refreshDiaries(); 
}




  String _username = 'Guest';
  bool _isLoading = true;
  bool _showFavoritesOnly = false;
  int _selectedIndex = 0;
  bool _showAllDiaries = false;

  final Map<String, String> _emojiMap = {
    'happy': '😊',
    'sad': '😢',
    'angry': '😠',
    'anxious': '😰',
    'neutral': '😐',
  };
  
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

    final matchesQuery = desc.contains(lowerQuery) ||
        mood.contains(lowerQuery) ||
        emoji.contains(lowerQuery) ||
        createdAt.contains(lowerQuery);

    final isFav = entry['isFavorite'] == 1;
    return _showFavoritesOnly ? matchesQuery && isFav : matchesQuery;
  }).toList();

  setState(() => _filteredDiaries = filtered);
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
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.5,
        ),
      ),
      filled: true,
      fillColor: Theme.of(context).cardColor,
    ),
    onChanged: _filterDiaries,
  ),
),


    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : Colors.grey,
            ),
            label: Text(
              _showFavoritesOnly ? 'Showing Favorites' : 'All Entries',
              style: GoogleFonts.quicksand(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
                _filterDiaries(_searchController.text);
              });
            },
          ),
        ],
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
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        final entry = _emojiMap.entries.elementAt(index);
        final selected = _feelingController.text == entry.key;
        return GestureDetector(
          onTap: () => setModalState(() {
            _feelingController.text = entry.key;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
                width: 2.5,
              ),
              color: selected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
            ),
            padding: const EdgeInsets.all(14),
            child: Center(
              child: Text(entry.value, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: _emojiMap.length,
    ),
  );
}



void _showForm(int? id) {
  final isEditing = id != null;
  final theme = Theme.of(context);

  if (isEditing) {
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
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? "Edit your vibes." : "Spill your vibes.",
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMoodPicker(setModalState),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe your vibes...',
                      filled: true,
                      fillColor: theme.cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    style: GoogleFonts.quicksand(fontSize: 15),
                  ),
                  const SizedBox(height: 24),
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

                      if (isEditing) {
                        await SQLHelper.updateDiary(id, feeling, desc);
                      } else {
                        await SQLHelper.createDiary(feeling, desc, DateTime.now());
                      }

                      Navigator.pop(context);
                      _refreshDiaries();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
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
                'assets/images/cat.gif',
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
    final displayList = _showAllDiaries ? _filteredDiaries : _filteredDiaries.take(3).toList();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshDiaries,
            child: ListView.builder(
              itemCount: displayList.length,
              padding: const EdgeInsets.only(bottom: 80),
              itemBuilder: (_, index) {
                final diary = displayList[index];
                final time = DateFormat('dd MMM yyyy, hh:mm a')
                    .format(DateTime.parse(diary['createdAt']));
                final mood = diary['feeling'].toString().toLowerCase();
                final borderColor = _getMoodBorderColor(context, mood);
                final isExpanded = _expandedCardIds.contains(diary['id']);
                return _buildDiaryCard(diary, time, borderColor, isExpanded);
              },
            ),
          ),
        ),
        if (_filteredDiaries.length > 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
  style: TextButton.styleFrom(
    backgroundColor: Theme.of(context).cardColor.withOpacity(0.4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  ),
  icon: Icon(
    _showAllDiaries ? Icons.expand_less : Icons.expand_more,
    color: Theme.of(context).iconTheme.color,
  ),
  label: Text(
    _showAllDiaries ? "Show less" : "See all entries",
    style: GoogleFonts.quicksand(
      fontWeight: FontWeight.w500,
      color: Theme.of(context).textTheme.bodyLarge?.color,
    ),
  ),
  onPressed: () {
    setState(() => _showAllDiaries = !_showAllDiaries);
  },
),

          ),
      ],
    );
  }
}


Widget _buildDiaryCard(Map<String, dynamic> diary, String time, Color borderColor, bool isExpanded) {
  final id = diary['id'];
  final description = diary['description'] ?? '';

  return Dismissible(
    key: Key(id.toString()),
    direction: DismissDirection.endToStart, // right to left
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.redAccent,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (_) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Entry"),
          content: const Text("Are you sure you want to delete this diary entry?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return confirm ?? false;
    },
    onDismissed: (_) async {
      // Temporarily store deleted diary for undo
      final deletedDiary = Map<String, dynamic>.from(diary);
      await _deleteDiary(id);

      // Show SnackBar with Undo option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Entry deleted"),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () async {
              await SQLHelper.createDiary(
                deletedDiary['feeling'],
                deletedDiary['description'],
                DateTime.parse(deletedDiary['createdAt']),
              );
              _refreshDiaries();
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    },
    child: GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedCardIds.contains(id)) {
            _expandedCardIds.remove(id);
          } else {
            _expandedCardIds.add(id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
            // Header Row
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

            // Description
            AnimatedCrossFade(
  firstChild: Text(
    description,
    style: GoogleFonts.quicksand(fontSize: 14),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
  secondChild: Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      description,
      style: GoogleFonts.quicksand(fontSize: 14),
    ),
  ),
  crossFadeState:
      isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
  duration: const Duration(milliseconds: 250),
  firstCurve: Curves.easeOut,
  secondCurve: Curves.easeIn,
),


            const SizedBox(height: 12),

            // Edit / Delete Buttons
            Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    IconButton(
  icon: Icon(
    diary['isFavorite'] == 1 ? Icons.favorite : Icons.favorite_border,
    color: diary['isFavorite'] == 1 ? Colors.red : Colors.grey,
  ),
  tooltip: "Favorite",
  onPressed: () {
    final isFav = diary['isFavorite'] == 1;
    _toggleFavorite(diary['id'], isFav); 
  },
),


    IconButton(
      icon: const Icon(Icons.edit, size: 20),
      tooltip: "Edit",
      onPressed: () => _showForm(id),
    ),
    IconButton(
      icon: const Icon(Icons.delete, size: 20),
      tooltip: "Delete",
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Entry"),
            content: const Text("Are you sure you want to delete this diary entry?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _deleteDiary(id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Entry deleted")),
          );
        }
      },
    ),
  ],
),
          ],
        ),
      ),
    ),
  );
}



  Widget _buildStreakWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final streak = _calculateStreak();
   final message = streak > 0
    ? "You're on a $streak-day streak, $_username!"
    : "Let's start your first vibe today, $_username!";


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
            height: 95,
            width: 95,
            
            child: Lottie.asset(
              streak > 0
                  ? 'assets/lottie/streak.json'
                  : 'assets/lottie/idlecat.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
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











  // Calculates the current diary streak (consecutive days with entries)
  int _calculateStreak() {
    if (_diaries.isEmpty) return 0;

    // Extract and sort unique entry dates (ignore time)
    final dates = _diaries
        .map<DateTime>((d) => DateTime.parse(d['createdAt']))
        .map((dt) => DateTime(dt.year, dt.month, dt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // descending

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }

    // Check if the latest entry is today, else streak is 0
    final today = DateTime.now();
    final latest = dates.first;
    if (!(latest.year == today.year &&
        latest.month == today.month &&
        latest.day == today.day)) {
      return 0;
    }

    return streak;
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
              FutureBuilder<File?>(
                future: _loadProfileImage(),
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  return CircleAvatar(
                    radius: 30,
                    backgroundImage: file != null
                        ? FileImage(file)
                        : const AssetImage("assets/images/profile.jpeg")
                            as ImageProvider,
                  );
                },
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
                      color: isDark ? const Color(0xFF1B1E21) : Colors.white,
                    ),
                  ),
                  Text(
                    "Welcome back!",
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF1B1E21) : Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 130,
            child: Lottie.asset(
              'assets/lottie/drawer_cat.json', // or any other animation
              fit: BoxFit.contain,
            ),
          ),
        ),

        const Divider(indent: 16, endIndent: 16, thickness: 1),
        ListTile(
  leading: Icon(LucideIcons.user, size: 22), // Profile
  title: Text("Profile", style: GoogleFonts.quicksand()),
  onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
    _loadUserInfo(); // Refresh on return
  },
),
ListTile(
  leading: Icon(LucideIcons.quote, size: 22), // Quotes
  title: Text("Quotes", style: GoogleFonts.quicksand()),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuotesPage()),
    );
  },
),
ListTile(
  leading: Icon(LucideIcons.settings, size: 22), // Settings
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