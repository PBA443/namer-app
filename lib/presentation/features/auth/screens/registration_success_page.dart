// ---------------------------------------------------
// FILE 2: lib/presentation/features/auth/screens/registration_success_page.dart (අලුත් File එකක්)
// ---------------------------------------------------
// Registration එක සාර්ථක වූ පසු පරිශීලකයාට පෙන්වන පිටුව.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'auth_gate.dart'; // AuthGate එකට නැවත යොමු කිරීමට

class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Success Icon ---
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 120,
              ),
              const SizedBox(height: 32),

              // --- Congratulations Text ---
              const Text(
                'Congratulations!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // --- Subtitle Text ---
              const Text(
                'You have successfully completed the\nregistration process.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),

              // --- Continue Button ---
              ElevatedButton(
                onPressed: () {
                  // "Continue" කළාම, AuthGate එකට යනවා.
                  // AuthGate එක බලලා, user ලොග් වෙලා සහ profile එකක් තියෙන නිසා,
                  // ඉබේම HomePage එකට යවයි.
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false, // පරණ routes ඔක්කොම අයින් කරනවා
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF07A0C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
