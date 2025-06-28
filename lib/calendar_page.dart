import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'sql_helper.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarPage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const CalendarPage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEntries();
  }

  void _fetchEntries() async {
    final diaries = await SQLHelper.getDiaries();
    final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    setState(() {
      _entries = diaries.where((d) {
        final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(d['createdAt']));
        return date == selectedDate;
      }).toList();
    });
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
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                child: TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                    _fetchEntries();
                  },
                  headerStyle: HeaderStyle(
                    titleTextStyle: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).iconTheme.color),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white),
                    defaultTextStyle: GoogleFonts.quicksand(),
                    weekendTextStyle: GoogleFonts.quicksand(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Text(
                      "No diary for selected date.",
                      style: GoogleFonts.quicksand(),
                    ),
                  )
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (_, index) {
                      final entry = _entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry['feeling'],
                                  style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  entry['description'],
                                  style: GoogleFonts.quicksand(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    DateFormat('hh:mm a').format(DateTime.parse(entry['createdAt'])),
                                    style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey),
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
        ],
      ),
    );
  }
}
