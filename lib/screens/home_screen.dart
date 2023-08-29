// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:personal_messenger/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

class home_screen extends StatefulWidget {
  const home_screen({super.key, required this.title});

  final String title;

  @override
  State<home_screen> createState() => _home_screenState();
}

class _home_screenState extends State<home_screen> {
  @override
  void initState() {
    super.initState();
  }

  void toggleDarkMode() {
    setState(() {
      final themeModel = Provider.of<ThemeModel>(context, listen: false);
      themeModel.isDark = !themeModel.isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context, listen: false);
    Color pickerColor = themeModel.colorTheme;

    void changeColor(Color color) {
      setState(() => pickerColor = color);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: pickerColor,
        title: Text(widget.title),
        actions: [
          IconButton(
            iconSize: 20,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Pick a color!'),
                    content: SingleChildScrollView(
                      child: BlockPicker(
                        pickerColor: pickerColor,
                        onColorChanged: changeColor,
                      ),
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            themeModel.colorTheme = pickerColor;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pickerColor,
                        ),
                        child: const Text('Got it'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.color_lens),
          ),
          IconButton(
            icon: themeModel.isDark
                ? const Icon(Icons.sunny)
                : const Icon(Icons.nights_stay),
            onPressed: toggleDarkMode,
          ),
        ],
      ),
      body: const SplashPage(),
    );
  }
}
