// lib/main.dart

import 'package:flutter/material.dart';
// Firebase Core package එක import කරගන්න
import 'package:firebase_core/firebase_core.dart';
// FlutterFire configure කළාම හැදෙන file එක import කරගන්න
import 'firebase_options.dart';
// අපේ StaffRideApp එක තියෙන file එක import කරගන්න
import 'app.dart'; // (ඔබේ app.dart file එකට අදාළව)

// main function එක async බවට පත් කරනවා
Future<void> main() async {
  // Flutter engine එක හරියටම පටන් ගත්තා කියලා තහවුරු කරගන්නවා
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase සේවාවන් පටන් ගන්නකන් බලාගෙන ඉන්නවා
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase පටන් ගත්තට පස්සේ App එක run කරනවා
  runApp(const StaffRideApp());
}
