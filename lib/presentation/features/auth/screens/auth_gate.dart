import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/firestore_service.dart';
// import 'home_page.dart'; // මෙය දැන් සාමාන්‍ය home page එකක් ලෙස අවශ්‍ය නොවනු ඇත
import 'signin_page.dart';
import 'role_selection_page.dart';
import '../../user_panel/home/screens/user_home_page.dart'; // User role එකට අදාළ home page එක
import '../../driver_panel/dashboard/screens/driver_dashboard_page.dart'; // Driver role එකට අදාළ home page එක

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService()
          .authStateChanges, // Firebase authentication state එකට සවන් දෙයි
      builder: (context, authSnapshot) {
        // Authentication state එක loading නම්, loading indicator එකක් පෙන්වයි
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // user කෙනෙක් sign in වෙලා නම්
        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;
          // user ගේ profile එක Firestore වලින් ලබා ගැනීමට FutureBuilder එකක් භාවිතා කරයි
          return FutureBuilder<Map<String, dynamic>?>(
            future: FirestoreService().getUserProfile(
              user.uid,
            ), // user profile එක ලබා ගනී
            builder: (context, profileSnapshot) {
              // Profile data loading නම්, loading indicator එකක් පෙන්වයි
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Profile data එක ලැබී ඇත්නම් සහ එය null නොවේ නම්
              if (profileSnapshot.hasData && profileSnapshot.data != null) {
                final userProfile = profileSnapshot.data!;
                final userRole =
                    userProfile['role']
                        as String?; // profile එකෙන් role එක ලබා ගනී

                // user role එක පරීක්ෂා කර අදාළ home page එකට යොමු කරයි
                if (userRole == 'user') {
                  // role එක 'user' නම්
                  return UserHomePage();
                } else if (userRole == 'driver') {
                  // role එක 'driver' නම්
                  return DriverDashboardPage();
                } else {
                  // Profile එක තිබුණත් role එක නැත්නම් හෝ වැරදි නම්, role තෝරාගැනීමේ පිටුවට යොමු කරයි
                  // මෙය අලුත් user කෙනෙක්ට හෝ role එකක් නැති user කෙනෙක්ට අදාළ වේ.
                  return RoleSelectionPage(user: user);
                }
              } else {
                // Profile එකක් හමු නොවූ විට (අලුත් user කෙනෙක්)
                return RoleSelectionPage(user: user);
              }
            },
          );
        } else {
          // user කෙනෙක් sign in වෙලා නැත්නම්, SignInPage එකට යොමු කරයි
          return const SignInPage();
        }
      },
    );
  }
}
