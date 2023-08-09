import 'package:flutter/material.dart';

class ThemeModel extends ChangeNotifier {
  Color _colorTheme = Colors.green;
  Color get colorTheme => _colorTheme;

  set colorTheme(Color newColor) {
    _colorTheme = newColor;
    notifyListeners();
  }

  bool _isDark = false;
  bool get isDark => _isDark;

  set isDark(bool newDarkLigth) {
    _isDark = newDarkLigth;
    notifyListeners();
  }
}

class AppTheme {
  final ThemeModel themeModel;

  AppTheme(this.themeModel);

  ThemeData getTheme() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: themeModel.colorTheme,
        appBarTheme: const AppBarTheme(elevation: 20),
        brightness: themeModel._isDark ? Brightness.dark : Brightness.light,
      );
}
