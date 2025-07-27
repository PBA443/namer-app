import 'package:flutter/material.dart';

// DriverHomePage එක වෙනම file එකක තියෙනවා නම්, main.dart එකෙන් මේක import කරගන්න.
// උදා: import 'package:your_app_name/ui/pages/driver_home_page.dart';

// ඔබට මෙය සම්පූර්ණ යෙදුමක් ලෙස පරීක්ෂා කිරීමට අවශ්‍ය නම්, main function එකත් මෙහි ඇතුළත් කළ හැක.
// එසේ නොමැති නම්, මෙම class එක පමණක් ඔබගේ project එකට එකතු කරන්න.
void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: Scaffold(
        body: ListView(
          children: [
            DriverHomePage(), // මෙහි DriverHomePage එක භාවිතා කර ඇත
          ],
        ),
      ),
    );
  }
}

class DriverHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375, // මෙය responsive කිරීමට MediaQuery භාවිතා කළ හැක
          height: 812, // මෙය responsive කිරීමට MediaQuery භාවිතා කළ හැක
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              // Top status bar section
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 375,
                  height: 44,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 375,
                          height: 44,
                          decoration: BoxDecoration(color: Colors.black),
                        ),
                      ),
                      // Battery icon
                      Positioned(
                        left: 336,
                        top: 17.33,
                        child: Opacity(
                          opacity: 0.35,
                          child: Container(
                            width: 22,
                            height: 11.33,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(width: 1, color: Colors.white),
                                borderRadius: BorderRadius.circular(2.67),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 338,
                        top: 19.33,
                        child: Container(
                          width: 18,
                          height: 7.33,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1.33),
                            ),
                          ),
                        ),
                      ),
                      // Time display
                      Positioned(
                        left: 21,
                        top: 13,
                        child: Container(
                          width: 54,
                          height: 21,
                          decoration: BoxDecoration(color: Colors.black),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 3,
                                child: SizedBox(
                                  width: 54,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '9:4',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'SF Pro Text',
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.28,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '1',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'SF Pro Text',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Main content: "Hi, nice to meet you!"
              Positioned(
                left: 37,
                top: 425,
                child: Text(
                  'Hi,nice to meet you!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // "Choose your Route" text with underline
              Positioned(
                left: 125,
                top: 496,
                child: Text(
                  'Choose your Route',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFF0C414),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              // This positioned widget seems to be an empty container, possibly a placeholder from Figma
              Positioned(
                left: 258,
                top: 764,
                child: Container(
                  width: 9,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom home indicator bar
              Positioned(
                left: -3,
                top: 778,
                child: Container(
                  width: 375,
                  height: 34,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 121,
                        top: 20,
                        child: Container(
                          width: 134,
                          height: 5,
                          decoration: ShapeDecoration(
                            color: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
