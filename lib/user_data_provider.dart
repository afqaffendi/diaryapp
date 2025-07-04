import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDataProvider with ChangeNotifier {
  String _username = 'Guest';
  File? _profileImage;

  String get username => _username;
  File? get profileImage => _profileImage;

  UserDataProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Guest';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/profile.png');
    if (await file.exists()) {
      _profileImage = file;
    }

    notifyListeners();
  }

  Future<void> updateUsername(String newName) async {
    _username = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);
    notifyListeners();
  }

  Future<void> updateProfileImage(File image) async {
  final directory = await getApplicationDocumentsDirectory();
  final savedImage = await image.copy('${directory.path}/profile.png');
  _profileImage = savedImage;
  notifyListeners();
}

}
