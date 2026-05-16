import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const NetStableApp());
}

class NetStableApp extends StatelessWidget {
  const NetStableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff121212),
        primaryColor: Colors.greenAccent,
      ),
      home: const DashboardScreen(),
    );
  }
}
