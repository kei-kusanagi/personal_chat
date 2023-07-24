import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:personal_messenger/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

class home_screen extends StatefulWidget {
  home_screen({super.key, required this.title});

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
                        child: const Text('Got it'),
                        onPressed: () {
                          setState(() {
                            themeModel.colorTheme = pickerColor;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pickerColor,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.color_lens),
          ),
          IconButton(
            icon:
                themeModel.isDark ? Icon(Icons.sunny) : Icon(Icons.nights_stay),
            onPressed: toggleDarkMode,
          ),
        ],
      ),
      ////////////////// TU CODIGO VA AQUI //////////////////
      body: SplashPage(),
    );
  }
}
