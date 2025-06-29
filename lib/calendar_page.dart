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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B1E21) : const Color(0xFFDAD4CF);
    final borderColor = isDark ? Color(0xFFDAD4CF) : Color(0xFF1B1E21);

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
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
    todayDecoration: BoxDecoration(
      color: const Color(0xFFFADB14).withOpacity(0.4),
      shape: BoxShape.circle,
    ),
    selectedDecoration: const BoxDecoration(
      color: Color(0xFFFF7A45),
      shape: BoxShape.circle,
    ),
    markersMaxCount: 1,
    markerDecoration: const BoxDecoration(), // we override below
    markersAlignment: Alignment.bottomCenter,
    markerMargin: const EdgeInsets.only(top: 2),
  ),
  calendarBuilders: CalendarBuilders(
    markerBuilder: (context, date, events) {
      final diaryForDay = _allDiaries.firstWhere(
        (entry) =>
            DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['createdAt'])) ==
            DateFormat('yyyy-MM-dd').format(date),
        orElse: () => {},
      );

      if (diaryForDay.isEmpty) return const SizedBox();

      final feeling = diaryForDay['feeling']?.toString().toLowerCase() ?? '';
      final emojiMap = {
        'happy': '😊',
        'sad': '😢',
        'angry': '😠',
        'anxious': '😰',
        'neutral': '😐',
      };

      return Text(
        emojiMap[feeling] ?? '📝',
        style: const TextStyle(fontSize: 16),
      );
    },
  ),
  headerStyle: HeaderStyle(
    titleTextStyle: GoogleFonts.quicksand(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    formatButtonVisible: false,
    titleCentered: true,
  ),
  daysOfWeekStyle: DaysOfWeekStyle(
    weekdayStyle: GoogleFonts.quicksand(fontSize: 12),
    weekendStyle: GoogleFonts.quicksand(fontSize: 12),
  ),
),

            const SizedBox(height: 16),
            Expanded(
              child: _filteredDiaries.isEmpty
                  ? Center(
                      child: Text("No entries on this day.",
                          style: GoogleFonts.quicksand(fontSize: 20)))
                  : ListView.builder(
                      itemCount: _filteredDiaries.length,
                      itemBuilder: (_, index) {
                        final diary = _filteredDiaries[index];
                        final time = DateFormat('hh:mm a')
                            .format(DateTime.parse(diary['createdAt']));

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            key: Key(diary['id'].toString()),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              border: Border.all(
                                  color: borderColor.withOpacity(0.8),
                                  width: 3.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(diary['feeling'],
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18)),
                                    const Spacer(),
                                    Text(time,
                                        style: GoogleFonts.quicksand(
                                            fontSize: 14,
                                            color: const Color.fromARGB(255, 106, 106, 106))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(diary['description'],
                                    style:
                                        GoogleFonts.quicksand(fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
