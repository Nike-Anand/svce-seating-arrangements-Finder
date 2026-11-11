import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/background_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service for reminders
  await initializeBackgroundService();
  
  runApp(const SVCESeatingApp());
}

class SVCESeatingApp extends StatelessWidget {
  const SVCESeatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVCE Seating Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}