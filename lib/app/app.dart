import 'package:flutter/material.dart';
import '../design/theme.dart';
import '../home/home_screen.dart';

class LexioApp extends StatelessWidget {
  const LexioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slove',
      debugShowCheckedModeBanner: false,
      theme: LexioTheme.light,
      home: const HomeScreen(),
    );
  }
}
