import 'package:flutter/material.dart';
import 'pages/register.dart';
import 'pages/login.dart';
import 'pages/tripHistory.dart';
import 'pages/homePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'Safety Score Tracker'),  // Provide the required 'title' parameter
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/tripHistory': (context) =>  TripHistoryPage(),
      },
    );
  }
}