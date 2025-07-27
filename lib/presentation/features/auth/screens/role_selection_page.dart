// ---------------------------------------------------
// FILE: lib/presentation/features/auth/screens/role_selection_page.dart (නිවැරදි කරන ලද කේතය)
// ---------------------------------------------------
// Constructor එක සහ logic එක නිවැරදි කර ඇත.
// ---------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart'; // <-- User class එක සඳහා අනිවාර්යයි
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/services/firestore_service.dart';
import 'driver_registration/driver_personal_info_page.dart';
import 'user_registration/user_personal_info_page.dart';

class RoleSelectionPage extends StatefulWidget {
  // --- නිවැරදි කිරීම 1: Constructor එක නිවැරදි කිරීම ---
  // AuthGate එකෙන් එන user object එක ලබාගැනීමට constructor එක හදනවා.
  final User user;
  const RoleSelectionPage({super.key, required this.user});
  // ----------------------------------------------------

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // --- නිවැරදි කිරීම 2: AuthGate එකෙන් ආපු user object එක පාවිච්චි කිරීම ---
      // AuthService().currentUser වෙනුවට widget.user භාවිතා කරනවා.
      await FirestoreService().createUserProfile(user: widget.user, role: role);
      // ----------------------------------------------------------------------

      if (!mounted) return;

      // --- නිවැරදි කිරීම 3: ඊළඟ පිටුවට user data යැවීම ---
      if (role == 'user') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UserPersonalInfoPage(user: widget.user),
          ),
        );
      } else if (role == 'driver') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DriverPersonalInfoPage(user: widget.user),
          ),
        );
      }
      // ----------------------------------------------------
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save role. Please try again.")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: const Text(
          'Join Us',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Choose Your Role',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How would you like to use StaffRide?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 48),
                    _RoleCard(
                      iconPath: 'assets/images/user_icon.svg',
                      title: "I'm a User",
                      subtitle: 'Find and book rides with ease.',
                      onTap: () => _selectRole('user'),
                    ),
                    const SizedBox(height: 24),
                    _RoleCard(
                      iconPath: 'assets/images/driver_icon.svg',
                      title: "I'm a Driver",
                      subtitle: 'Offer rides and earn money.',
                      onTap: () => _selectRole('driver'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// _RoleCard widget එකේ වෙනසක් නැහැ
class _RoleCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SvgPicture.asset(iconPath, height: 60, width: 60),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
