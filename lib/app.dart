// lib/app.dart

import 'package:flutter/material.dart';
import 'package:staff_ride/presentation/features/auth/screens/auth_gate.dart';
// SignInPage එකේ path එක මෙතනට දෙන්න.
// 'your_project_name' වෙනුවට ඔබේ project එකේ නම යොදන්න (pubspec.yaml එකේ තියෙන නම).

class StaffRideApp extends StatelessWidget {
  const StaffRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StaffRide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFDD734),
        fontFamily: 'Lexend',
        scaffoldBackgroundColor: const Color(0xFFFDD734),
      ),
      // App එකේ මුල්ම පිටුව ලෙස AuthGate එක ලබා දෙනවා
      home: const AuthGate(),
    );
  }
}
