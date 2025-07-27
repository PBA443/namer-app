// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:staff_ride/app.dart';

void main() {
  // 'testWidgets' function එකෙන් අපි test case එකක් define කරනවා.
  // පළවෙනියට දෙන්නේ test එකේ නම/විස්තරය.
  testWidgets('SignInPage UI Test - Verifies content is displayed correctly', (
    WidgetTester tester,
  ) async {
    // පියවර 1: අපේ app එක build කරනවා
    // tester.pumpWidget() එකෙන් අපි test කරන්න ඕන widget එක test environment එකේ render කරනවා.
    // මෙතනදී අපි සම්පූර්ණ StaffRideApp එකම දෙනවා, මොකද ඒකේ තමයි MaterialApp එක තියෙන්නේ.
    await tester.pumpWidget(const StaffRideApp());

    // පියවර 2: UI එකේ තියෙන දේවල් හරිද කියලා පරීක්ෂා කරනවා

    // 'find.text()' එකෙන් අදාළ text එක තියෙන widget එකක් තියෙනවද කියලා හොයනවා.
    // 'expect()' function එකෙන්, අපි හොයපු දේ ('findsOneWidget' - එක widget එකක් හම්බවෙන්න ඕන)
    // ඇත්තටම වෙලාද කියලා තහවුරු කරනවා.

    // ප්‍රධාන මාතෘකාව තියෙනවද කියලා බලනවා
    expect(find.text('Flutter Run Test Successful!'), findsOneWidget);

    // උප මාතෘකාව තියෙනවද කියලා බලනවා
    expect(
      find.text('Your file structure is working perfectly.'),
      findsOneWidget,
    );

    // කොළ පාට හරි ලකුණ (Icon) තියෙනවද කියලා බලනවා
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // AppBar එකේ title එක තියෙනවද කියලා බලනවා
    expect(find.text('StaffRide App'), findsOneWidget);
  });
}
