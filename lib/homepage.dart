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
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';


class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomePage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> with TickerProviderStateMixin {

Set<int> _expandedCardIds = {};

final TextEditingController _searchController = TextEditingController();
List<Map<String, dynamic>> _filteredDiaries = [];

  final Map<String, String> _emojiMap = {
    'happy': '😊',
    'sad': '😢',
    'angry': '😠',
    'anxious': '😰',
    'neutral': '😐',
  };


String _getWeatherLottie(String weather) {
  switch (weather.toLowerCase()) {
    case 'clear':
      return 'assets/lottie/sun.json';
    case 'clouds':
      return 'assets/lottie/cloudy.json';
    case 'rain':
      return 'assets/lottie/rain.json';
    case 'thunderstorm':
      return 'assets/lottie/storm.json';
    case 'snow':
      return 'assets/lottie/snow.json';
    case 'mist':
    case 'fog':
      return 'assets/lottie/mist.json';
    default:
      return 'assets/lottie/cloudy.json';
  }
}

String? _weatherMain;
double? _weatherTemp;
String? _weatherCity = 'Kuala Lumpur';

late AnimationController _weatherAnimController;
late Animation<Offset> _weatherSlideAnimation;
bool _showWeather = false;

Future<void> _fetchWeather() async {
  final apiKey = '6fbc0ac6a982a880c673728ee4da2c89';
  final city = Uri.encodeComponent(_weatherCity!);
  final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

  try {
  final res = await http.get(Uri.parse(url));
  print('Weather response: ${res.body}'); // ← Add this
  if (res.statusCode == 200) {
    final json = jsonDecode(res.body);
    setState(() {
      _weatherMain = json['weather'][0]['main'];
      _weatherTemp = json['main']['temp'].toDouble();
    });
  } else {
    debugPrint('Weather API error: ${res.statusCode}');
  }
} catch (e) {
  debugPrint('Weather request failed: $e');
}

}
  String _username = 'Guest';
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _selectedIndex = 0;
  String? _profileImagePath;

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Guest';
      _profileImagePath = prefs.getString('profileImagePath');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? const Color(0xFF1B1E21) : const Color(0xFFFDAD4CF);
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context, isDark),
      body: Column(
  children: [

    Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: TextField(
    controller: _searchController,
    onChanged: _filterDiaries,
    decoration: InputDecoration(
      hintText: 'Search entries...',
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  ),
),


    _buildAnimatedWeatherWidget(),
    Expanded(child: _buildDiaryList()),
  ],
),

      bottomNavigationBar: _buildBottomNav(isDark, selectedColor),
    );
  }

@override
void initState() {
  super.initState();
  _refreshDiaries();
  _loadUserInfo();
  _fetchWeather();

  _weatherAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  _weatherSlideAnimation = Tween<Offset>(
    begin: const Offset(0, -0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _weatherAnimController,
    curve: Curves.easeOut,
  ));

  SchedulerBinding.instance.addPostFrameCallback((_) {
    setState(() => _showWeather = true);
    _weatherAnimController.forward();
  });
}


Future<void> _refreshDiaries() async {
  final data = await SQLHelper.getDiaries();
  setState(() {
    _diaries = data;
    _filteredDiaries = data;
    _isLoading = false;
  });
}

void _filterDiaries(String query) {
  final filtered = _diaries.where((entry) {
    final description = entry['description'].toString().toLowerCase();
    final feeling = entry['feeling'].toString().toLowerCase();
    return description.contains(query.toLowerCase()) || feeling.contains(query.toLowerCase());
  }).toList();

  setState(() => _filteredDiaries = filtered);
}



  String _getMoodEmoji(String feeling) =>
      _emojiMap[feeling.toLowerCase()] ?? '📝';

  Color _getMoodBorderColor(BuildContext context, String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFC97B63);
      case 'sad':
      case 'anxious':
        return const Color.fromARGB(255, 30, 45, 64);
      case 'angry':
        return const Color.fromARGB(255, 190, 52, 47);
      case 'neutral':
        return const Color.fromARGB(255, 104, 102, 109);
      default:
        return Theme.of(context).colorScheme.outline;
    }
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Spill your vibes.",
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 12),
                    _buildMoodPicker(setModalState),
                    const SizedBox(height: 16),
                    _buildDescriptionField(setModalState),
                    const SizedBox(height: 16),
                    _buildSubmitButton(modalContext, id, isDark),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 18,
              child: SizedBox(
                height: 90,
                child: Image.asset('assets/images/cat.gif', fit: BoxFit.contain),
              ),
            ),
          ],
        ),
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
                  color: selected ? const Color(0xFFF1B1E21) : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
                color: selected ? Colors.grey.withOpacity(0.3) : Colors.transparent,
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

  Widget _buildDescriptionField(Function setModalState) {
    return TextField(
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
    );
  }

  Widget _buildSubmitButton(BuildContext context, int? id, bool isDark) {
    final canSubmit = _feelingController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty;
    return ElevatedButton(
      onPressed: () async {
        if (!canSubmit) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Complete both fields")));
          return;
        }
        if (id == null) {
          await SQLHelper.createDiary(
              _feelingController.text, _descriptionController.text, DateTime.now());
        } else {
          await SQLHelper.updateDiary(
              id, _feelingController.text, _descriptionController.text);
        }
        _refreshDiaries();
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor:
            canSubmit ? (isDark ? Colors.white : Colors.black) : Colors.grey,
        side: BorderSide(
          color: canSubmit
              ? (isDark ? Colors.white : Colors.black)
              : Colors.grey.withOpacity(0.5),
          width: 2.5,
        ),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(18),
        elevation: 0,
      ),
      child: const Icon(Icons.check, size: 24),
    );
  }

  Drawer _buildDrawer(BuildContext context, bool isDark) {
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
                  backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
                      ? FileImage(File(_profileImagePath!))
                      : const AssetImage("assets/images/profile.png") as ImageProvider,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hi, $_username!",
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
              _loadUserInfo(); // reload image + username
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
    );
  }

  Widget _buildFAB(bool isDark) {
    return SizedBox(
      height: 60,
      width: 60,
      child: FloatingActionButton(
        backgroundColor: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFFF1B1E21),
        elevation: 5,
        shape: const CircleBorder(),
        onPressed: () => _showForm(null),
        child: Icon(Icons.add,
            size: 30, color: isDark ? const Color(0xFFF1B1E21) : Colors.white),
      ),
    );
  }

Widget _buildBottomNav(bool isDark, Color selectedColor) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20.0),
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
      borderRadius: BorderRadius.circular(50),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(LucideIcons.home,
              color: _selectedIndex == 0 ? selectedColor : Colors.grey),
          onPressed: () => _onNavTap(0),
        ),
        GestureDetector(
          onTap: () => _showForm(null),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFFFDAD4CF) : const Color(0xFF1B1E21),
            ),
            child: Icon(
              Icons.add,
              size: 28,
              color: isDark ? const Color(0xFF1B1E21) : Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: Icon(LucideIcons.calendar,
              color: _selectedIndex == 1 ? selectedColor : Colors.grey),
          onPressed: () => _onNavTap(1),
        ),
      ],
    ),
  );
}






  AppBar _buildAppBar(BuildContext context) {
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

Widget _buildDiaryList() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  } else if (_diaries.isEmpty) {
    return const Center(child: Text("No entries yet."));
  } else {
    return RefreshIndicator(
      onRefresh: _refreshDiaries,
      child: ListView.builder(
        itemCount: _filteredDiaries.length,
        padding: const EdgeInsets.only(bottom: 0),
        itemBuilder: (_, index) {
          final diary = _filteredDiaries[index];
          final time = DateFormat('dd MMM yyyy, hh:mm a')
              .format(DateTime.parse(diary['createdAt']));
          final mood = diary['feeling'].toString().toLowerCase();
          final borderColor = _getMoodBorderColor(context, mood);

          return _buildDiaryCard(diary, time, borderColor);
        },
      ),
    );
  }
}


Widget _buildDiaryCard(Map<String, dynamic> diary, String time, Color borderColor) {
  final mood = diary['feeling'].toString().toLowerCase();
  final id = diary['id'] as int;
  final isExpanded = _expandedCardIds.contains(id);
  final description = diary['description'];

  return Dismissible(
    key: Key(id.toString()),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.redAccent,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    onDismissed: (_) async {
      await _deleteDiary(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry deleted")),
      );
    },
    child: GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
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
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: borderColor.withOpacity(0.15),
                  child: Text(
                    _getMoodEmoji(mood),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(diary['feeling'],
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text(time, style: GoogleFonts.quicksand(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              firstChild: Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.quicksand(fontSize: 14),
              ),
              secondChild: Text(
                description,
                style: GoogleFonts.quicksand(fontSize: 14),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showForm(id),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteDiary(id),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}




  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    _refreshDiaries();
  }

Widget _buildAnimatedWeatherWidget() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardColor = Theme.of(context).cardColor;

  final hasData = _weatherMain != null && _weatherTemp != null;
  final displayText = hasData
      ? '$_weatherMain, ${_weatherTemp!.round()}°C'
      : 'Fetching weather...';

  return AnimatedOpacity(
    duration: const Duration(milliseconds: 500),
    opacity: _showWeather ? 1 : 0,
    child: SlideTransition(
      position: _weatherSlideAnimation,
      child: Container(
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
  height: 60,
  width: 60,
  child: hasData
       ? Lottie.asset(_getWeatherLottie(_weatherMain!), fit: BoxFit.contain)
      : const CircularProgressIndicator(),
),
const SizedBox(width: 16),
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      displayText,
      style: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    Text(
      _weatherCity ?? '',
      style: GoogleFonts.quicksand(
        fontSize: 14,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    ),
  ],
),

            IconButton(
              icon: const Icon(Icons.refresh, size: 24),
              onPressed: () async {
                await _fetchWeather();
                if (_weatherMain != null && _weatherTemp != null) {
                  _weatherAnimController
                    ..reset()
                    ..forward();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Weather fetch failed.")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
}
