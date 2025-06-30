import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'sql_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const CalendarPage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _allDiaries = [];
  List<Map<String, dynamic>> _filteredDiaries = [];

  final Map<String, String> _emojiMap = {
    'happy': '😊',
    'sad': '😢',
    'angry': '😠',
    'anxious': '😰',
    'neutral': '😐',
  };

  final Map<String, Color> _moodBorderColors = {
    'happy': Color(0xFFC97B63),
    'sad': Color.fromARGB(255, 30, 45, 64),
    'angry': Color(0xFFBE342F),
    'anxious': Color.fromARGB(255, 30, 45, 64),
    'neutral': Color(0xFF68666D),
  };

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _allDiaries = data;
      _filterDiariesByDate(_selectedDay ?? DateTime.now());
    });
  }

  void _filterDiariesByDate(DateTime date) {
    final filtered = _allDiaries.where((entry) {
      final entryDate = DateTime.parse(entry['createdAt']);
      return DateFormat('yyyy-MM-dd').format(entryDate) ==
          DateFormat('yyyy-MM-dd').format(date);
    }).toList();

    setState(() {
      _filteredDiaries = filtered;
    });
  }

  Color _getBorderColor(String mood, ThemeData theme) {
    return _moodBorderColors[mood.toLowerCase()] ??
        theme.colorScheme.outline.withOpacity(0.6);
  }

  void _showForm(int? id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (id != null) {
      final existing = _filteredDiaries.firstWhere((e) => e['id'] == id);
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
                              const SnackBar(
                                  content: Text("Complete both fields")));
                          return;
                        }

                        if (id == null) {
                          await SQLHelper.createDiary(feeling, desc);
                        } else {
                          await SQLHelper.updateDiary(id, feeling, desc);
                        }

                        Navigator.pop(context);
                        _loadDiaries();
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
                child: Image.asset('assets/images/cat.gif',
                    fit: BoxFit.contain),
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

  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    _loadDiaries();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Calendar",
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                _filterDiariesByDate(selected);
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: GoogleFonts.quicksand(
                  color: textColor,
                  fontSize: 14,
                ),
                weekendTextStyle: GoogleFonts.quicksand(
                  color: textColor.withOpacity(0.85),
                  fontSize: 14,
                ),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final diaryForDay = _allDiaries.firstWhere(
                    (entry) =>
                        DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(entry['createdAt'])) ==
                        DateFormat('yyyy-MM-dd').format(date),
                    orElse: () => {},
                  );

                  if (diaryForDay.isEmpty) return const SizedBox();

                  final feeling = diaryForDay['feeling']?.toString().toLowerCase() ?? '';
                  return Text(
                    _emojiMap[feeling] ?? '📝',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                formatButtonVisible: false,
                titleCentered: true,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: textColor,
                ),
                weekendStyle: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: textColor.withOpacity(0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredDiaries.isEmpty
                  ? Center(
                      child: Text("No entries on this day.",
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            color: textColor.withOpacity(0.6),
                          )),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDiaries,
                      child: ListView.builder(
                        itemCount: _filteredDiaries.length,
                        itemBuilder: (_, index) {
                          final diary = _filteredDiaries[index];
                          final time = DateFormat('hh:mm a')
                              .format(DateTime.parse(diary['createdAt']));
                          final mood = diary['feeling'].toString().toLowerCase();
                          final borderColor = _getBorderColor(mood, theme);

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
                           child: GestureDetector(
  onTap: () => _showForm(diary['id']),
  child: Container(
    key: Key("diary-${diary['id']}"),
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: theme.cardColor,
      border: Border.all(
        color: borderColor,
        width: 3,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: borderColor.withOpacity(0.15),
              child: Text(
                _emojiMap[mood] ?? '📝',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                diary['feeling'],
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ),
            Text(
              time,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          diary['description'],
          style: GoogleFonts.quicksand(
            fontSize: 14,
            color: textColor.withOpacity(0.85),
          ),
        ),
      ],
    ),
  ),
),
                          );
                        },
                      ),
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        backgroundColor:
            isDark ? const Color(0xFFFDAD4CF) : const Color(0xFFF1B1E21),
        child: Icon(Icons.add,
            color: isDark ? const Color(0xFFF1B1E21) : Colors.white),
      ),
    );
  }
}
