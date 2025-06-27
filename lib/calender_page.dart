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
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar", style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
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
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text("No diary for selected date."))
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (_, index) {
                      final entry = _entries[index];
                      return ListTile(
                        title: Text(entry['feeling']),
                        subtitle: Text(entry['description']),
                        trailing: Text(DateFormat('hh:mm a').format(DateTime.parse(entry['createdAt']))),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
