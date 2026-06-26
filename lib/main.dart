import 'dart:async';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';

void main() {
  runApp(const MatchlyApp());
}

class MatchlyApp extends StatelessWidget {
  const MatchlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matchly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Text('Yükleniyor...', style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      ),
    );
  }
}
