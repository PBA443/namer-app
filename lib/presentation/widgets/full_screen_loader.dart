import 'package:flutter/material.dart';

class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ලස්සන loading indicator එකක්
            CircularProgressIndicator(
              color: Color(0xFFF07A0C), // App එකේ ප්‍රධාන වර්ණය
            ),
            SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
