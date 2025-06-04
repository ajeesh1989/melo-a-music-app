import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeMode get currentTheme => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme(); // Load saved theme on initialization
  }

  void toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _isDark);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDarkTheme') ?? false;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[300],
    primaryColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.black),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: Colors.grey[900],
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
  );
}
