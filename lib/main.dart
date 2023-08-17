import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bdhwkukeejylmfoxyygb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaHdrdWtlZWp5bG1mb3h5eWdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTAyMzM1MjMsImV4cCI6MjAwNTgwOTUyM30.9civyOj1ITEsIAFcwc0nrQB6ihqEcsg2hp2emylRaRQ',
  );

  final themeModel = ThemeModel();
  await themeModel.loadTheme();

  runApp(
    provider.ChangeNotifierProvider.value(
      value: themeModel,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = provider.Provider.of<ThemeModel>(context);
    final appTheme = AppTheme(themeModel);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme.getTheme(),
        home: home_screen(title: 'Personal Messenger 📨'));
  }
}
