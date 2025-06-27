import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshDiaries();
  }

  @override
  void dispose() {
    _feelingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  void _showForm(int? id) async {
    if (id != null) {
      final existing = _diaries.firstWhere((e) => e['id'] == id);
      _feelingController.text = existing['feeling'];
      _descriptionController.text = existing['description'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 5,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 25,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _feelingController,
              decoration: const InputDecoration(
                labelText: 'Feeling',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (id == null) {
                    await _addDiary();
                  } else {
                    await _updateDiary(id);
                  }

                  _feelingController.clear();
                  _descriptionController.clear();
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: Icon(id == null ? Icons.add : Icons.update),
                label: Text(id == null ? 'Create Entry' : 'Update Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDiary() async {
    final id = await SQLHelper.createDiary(
      _feelingController.text,
      _descriptionController.text,
    );
    if (id != -1) {
      _refreshDiaries();
    } else {
      _showErrorSnackbar("⚠️ Database not available (Web mode)");
    }
  }

  Future<void> _updateDiary(int id) async {
    final result = await SQLHelper.updateDiary(
      id,
      _feelingController.text,
      _descriptionController.text,
    );
    if (result != -1) {
      _refreshDiaries();
    } else {
      _showErrorSnackbar("⚠️ Cannot update in web mode");
    }
  }

  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted!')),
      );
      _refreshDiaries();
    }
  }

  void _showErrorSnackbar(String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
  appBar: AppBar(
    title: const Text("📔 Awie's Diary", textAlign: TextAlign.center),
    centerTitle: true,
  ),
  body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _diaries.isEmpty
          ? const Center(child: Text("No entries yet."))
          : ListView.builder(
              itemCount: _diaries.length,
              itemBuilder: (context, index) {
                final diary = _diaries[index];
                final createdAt = diary['createdAt'];
                String formatted = '';
                if (createdAt != null) {
                  try {
                    formatted = DateFormat('d MMMM yyyy, hh:mm a')
                        .format(DateTime.parse(createdAt));
                  } catch (_) {}
                }

                return Card(
                  color: Colors.teal.shade50,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.emoji_emotions_outlined),
                    title: Text(diary['feeling'], textAlign: TextAlign.center),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(diary['description']),
                        const SizedBox(height: 5),
                        Text(formatted,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showForm(diary['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteDiary(diary['id']),
                        ),
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
    notchMargin: 6.0,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            // Optional: add navigation or state handling
          },
        ),
        const SizedBox(width: 48), // space for FAB
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () {
            // Optional: add calendar feature
          },
        ),
      ],
    ),
  ),
);

  }
}
