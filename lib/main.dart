import 'package:flutter/material.dart';
import 'splash_screen.dart';  // Import the splash screen file

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weatherly',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SplashScreen(),  // Show splash screen first
      debugShowCheckedModeBanner: false,
    );
  }
}
