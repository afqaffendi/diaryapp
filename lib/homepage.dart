import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 15,
          right: 15,
          top: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 120,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _feelingController,
              decoration: const InputDecoration(hintText: 'What is your feeling?'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'Tell me more about it'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Text(id == null ? 'Create New' : 'Update'),
              onPressed: () async {
                if (id == null) {
                  await _addDiary();
                } else {
                  await _updateDiary(id);
                }

                _feelingController.clear();
                _descriptionController.clear();
                if (mounted) Navigator.of(context).pop();
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> _addDiary() async {
    final id = await SQLHelper.createDiary(
        _feelingController.text, _descriptionController.text);
    if (id != -1) {
      _refreshDiaries();
    } else {
      _showError("SQLite is not available on web mode");
    }
  }

  Future<void> _updateDiary(int id) async {
    final res = await SQLHelper.updateDiary(
        id, _feelingController.text, _descriptionController.text);
    if (res != -1) {
      _refreshDiaries();
    } else {
      _showError("Failed to update diary.");
    }
  }

  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully deleted diary')),
    );
    _refreshDiaries();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Color(0xFFF2F2F2),
      appBar: AppBar(
  title: const Text(
    "Awie's Diary",
    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  ),
  centerTitle: true,
),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diaries.isEmpty
              ? const Center(child: Text("No diary entries"))
              : ListView.builder(
                  itemCount: _diaries.length,
                  itemBuilder: (context, index) {
                    final diary = _diaries[index];
                    final date = DateTime.tryParse(diary['createdAt'] ?? '');
                    final formatted = date != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                        : '';
                    return Card(
  color: Colors.white,
  elevation: 4,
  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal[100],
        radius: 28,
        child: ClipOval(
          child: Image.asset(
            'assets/images/happy.gif',
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diary['feeling'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            diary['description'],
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.teal),
            onPressed: () => _showForm(diary['id']),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deleteDiary(diary['id']),
          ),
        ],
      ),
    ),
  ),
);

                  },
                ),
     floatingActionButton: FloatingActionButton(
  backgroundColor: Colors.teal,
  child: const Icon(Icons.add),
  onPressed: () => _showForm(null),
),

    );
  }
}
