import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calendar_page.dart'; 
import 'sql_helper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_page.dart';
import 'settings_page.dart';


class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomePage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, String> _emojiMap = {
    'happy': '🥰',
    'sad': '😔',
    'angry': '😤',
    'excited': '🤩',
    'tired': '😮‍💨',
    'love': '💖',
    'reflective': '🌙',
    'anxious': '😰',
    'motivated': '🔥',
  };

  String _getMoodEmoji(String feeling) {
    return _emojiMap[feeling.toLowerCase()] ?? '📝';
  }

  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshDiaries();
  }

  Future<void> _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

 void _showForm(int? id) {
  if (id != null) {
    final existing = _diaries.firstWhere((element) => element['id'] == id);
    _feelingController.text = existing['feeling'];
    _descriptionController.text = existing['description'];
  } else {
    _feelingController.clear();
    _descriptionController.clear();
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => StatefulBuilder(
      builder: (BuildContext modalContext, StateSetter setModalState) {
        return AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOut,
  padding: EdgeInsets.fromLTRB(
    16,
    16,
    16,
    MediaQuery.of(context).viewInsets.bottom + 16,
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text("How are you feeling?", style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      SizedBox(
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _emojiMap.entries.map((entry) {
            final isSelected = _feelingController.text == entry.key;
            return GestureDetector(
              onTap: () => setModalState(() => _feelingController.text = entry.key),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Text(entry.value, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 4),
                    Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Write something...',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: () async {
          if (_feelingController.text.isEmpty || _descriptionController.text.isEmpty) {
            _showErrorSnackbar(modalContext, "Complete both fields");
            return;
          }
          if (id == null) {
            await SQLHelper.createDiary(_feelingController.text, _descriptionController.text);
          } else {
            await SQLHelper.updateDiary(id, _feelingController.text, _descriptionController.text);
          }
          _refreshDiaries();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.check),
        label: Text(id == null ? 'Add Entry' : 'Update Entry'),
      ),
    ],
  ),
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

  int _selectedIndex = 0;

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CalendarPage(toggleTheme: widget.toggleTheme),
  ),
);
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home", style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),

  drawer: Drawer(
  backgroundColor: Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2C)
      : const Color(0xFFFFF5F0),
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      DrawerHeader(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3B3C)
              : const Color.fromARGB(255, 255, 233, 233),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage("assets/images/profile.png"),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, Afiq!",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Welcome back!",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ListTile(
        leading: Icon(Icons.person, color: Theme.of(context).iconTheme.color),
        title: Text(
          "Profile",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        },
      ),
      ListTile(
        leading: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
        title: Text(
          "Settings",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        onTap: () {
          Navigator.pop(context);
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
),





      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diaries.isEmpty
              ? const Center(child: Text("No entries yet."))
              : ListView.builder(
                  itemCount: _diaries.length,
                  itemBuilder: (_, index) {
                    final diary = _diaries[index];
                    final time = DateFormat('dd MMM yyyy, hh:mm a')
                        .format(DateTime.parse(diary['createdAt']));
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.teal.withOpacity(0.2),
                                  child: Text(_getMoodEmoji(diary['feeling']), style: const TextStyle(fontSize: 20)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(diary['feeling'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Text(time, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(diary['description'], style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showForm(diary['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () => _deleteDiary(diary['id']),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(LucideIcons.home,
                    color: _selectedIndex == 0 ? Theme.of(context).iconTheme.color : Colors.grey),
                onPressed: () => _onNavTap(0),
              ),
              IconButton(
                icon: Icon(LucideIcons.calendar,
                    color: _selectedIndex == 1 ? Theme.of(context).iconTheme.color : Colors.grey),
                onPressed: () => _onNavTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
