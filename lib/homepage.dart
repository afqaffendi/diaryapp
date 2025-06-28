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

  String _getMoodEmoji(String feeling) => _emojiMap[feeling.toLowerCase()] ?? '📝';

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
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => StatefulBuilder(
      builder: (modalContext, setModalState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Add your floating-style GIF
              SizedBox(
                height: 90,
                child: Image.asset(
                  'assets/imagesmood-unscreen.gif',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "How are you feeling?",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _emojiMap.entries.map((entry) {
                    final selected = _feelingController.text == entry.key;
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => _feelingController.text = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.teal
                                : const Color(0xFFD3D3D3).withOpacity(0.3),
                            width: 2,
                          ),
                          color: selected
                              ? Colors.teal.withOpacity(0.1)
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

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  if (_feelingController.text.isEmpty ||
                      _descriptionController.text.isEmpty) {
                    _showErrorSnackbar(modalContext, "Complete both fields");
                    return;
                  }
                  if (id == null) {
                    await SQLHelper.createDiary(
                        _feelingController.text, _descriptionController.text);
                  } else {
                    await SQLHelper.updateDiary(
                        id, _feelingController.text, _descriptionController.text);
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
        MaterialPageRoute(builder: (_) => CalendarPage(toggleTheme: widget.toggleTheme)),
      );
    }
    setState(() => _selectedIndex = index);
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
        backgroundColor: bgColor,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/images/profile.png"),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hi, Afiq!",
                          style: GoogleFonts.quicksand(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Welcome back!",
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          )),
                    ],
                  )
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text("Profile", style: GoogleFonts.quicksand()),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text("Settings", style: GoogleFonts.quicksand()),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsPage(toggleTheme: widget.toggleTheme)),
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _diaries.length,
                    itemBuilder: (_, index) {
                      final diary = _diaries[index];
                      final time = DateFormat('dd MMM yyyy, hh:mm a')
                          .format(DateTime.parse(diary['createdAt']));

                      return Dismissible(
                        key: Key(diary['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await _deleteDiary(diary['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Entry deleted")),
                          );
                        },
                        child: Card(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.teal.withOpacity(0.15),
                                      child: Text(
                                        _getMoodEmoji(diary['feeling']),
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        diary['feeling'],
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Text(time,
                                        style: GoogleFonts.quicksand(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(diary['description'],
                                    style: GoogleFonts.quicksand(fontSize: 14)),
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
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showForm(null),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: isDark ? Colors.black : Colors.grey[100],
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(LucideIcons.home,
                    color: _selectedIndex == 0 ? Colors.teal : Colors.grey),
                onPressed: () => _onNavTap(0),
              ),
              IconButton(
                icon: Icon(LucideIcons.calendar,
                    color: _selectedIndex == 1 ? Colors.teal : Colors.grey),
                onPressed: () => _onNavTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
