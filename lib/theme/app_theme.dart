import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModel extends ChangeNotifier {
  Color _colorTheme = Colors.green; // Asigna un valor predeterminado
  Color get colorTheme => _colorTheme;

  set colorTheme(Color newColor) {
    _colorTheme = newColor;
    notifyListeners();
  }

  bool _isDark = false; // Asigna un valor predeterminado
  bool get isDark => _isDark;

  set isDark(bool newDarkLight) {
    _isDark = newDarkLight;
    notifyListeners();
  }

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _colorTheme = Color(prefs.getInt('colorTheme') ?? Colors.green.value);
    _isDark = prefs.getBool('isDark') ?? false;

    notifyListeners();
  }

  void setColorTheme(Color newColor) async {
    _colorTheme = newColor;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('colorTheme', newColor.value);
  }

  void setIsDark(bool newDarkLight) async {
    _isDark = newDarkLight;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', newDarkLight);
  }
}

class AppTheme {
  final ThemeModel themeModel;

  AppTheme(this.themeModel);

  ThemeData getTheme() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: themeModel.colorTheme,
        appBarTheme: const AppBarTheme(elevation: 20),
        brightness: themeModel.isDark ? Brightness.dark : Brightness.light,
      );
}
