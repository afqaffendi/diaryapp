import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""
      CREATE TABLE diary (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        feeling TEXT,
        description TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    """);
  }

  static Future<sql.Database?> openDB() async {
    if (kIsWeb) {
      debugPrint("⚠️ SQLite not available on web.");
      return null;
    }
    return sql.openDatabase(
      'diaryawie.db',
      version: 1,
      onCreate: (sql.Database db, int version) async {
        await createTables(db);
      },
    );
  }

  static Future<int> createDiary(String feeling, String? description) async {
    final db = await openDB();
    if (db == null) return -1;
    final data = {'feeling': feeling, 'description': description};
    return await db.insert('diary', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final db = await openDB();
    if (db == null) return [];
    return db.query('diary', orderBy: "id");
  }

  static Future<int> updateDiary(int id, String feeling, String? description) async {
    final db = await openDB();
    if (db == null) return -1;
    final data = {
      'feeling': feeling,
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
    };
    return await db.update('diary', data, where: "id = ?", whereArgs: [id]);
  }

  static Future<void> deleteDiary(int id) async {
    final db = await openDB();
    if (db == null) return;
    await db.delete('diary', where: "id = ?", whereArgs: [id]);
  }
}
