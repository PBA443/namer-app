// lib/data/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- Google Sign-In ක්‍රියාවලිය ---
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Google Sign-In prompt එක පෙන්වා, ගිණුම තෝරාගැනීම
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // 2. පරිශීලකයා sign-in එක cancel කළොත්, null return කිරීම
      if (googleUser == null) {
        debugPrint('Google sign in was cancelled by the user.');
        return null;
      }

      // 3. Google ගිණුමෙන් authentication details ලබාගැනීම
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Firebase වලට අවශ්‍ය credential එක, ලබාගත් access & id token වලින් සෑදීම
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Firebase වෙත credential එක ලබාදී sign-in වීම
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // 6. සාර්ථකව ලොග් වූ පරිශීලකයාගේ තොරතුරු return කිරීම
      debugPrint(
        'Successfully signed in with Google: ${userCredential.user?.displayName}',
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Firebase සම්බන්ධ දෝෂයක් ආවොත් print කිරීම
      debugPrint("Firebase Auth Error during Google sign-in: ${e.message}");
      return null;
    } catch (e) {
      // වෙනත් ඕනෑම දෝෂයක් ආවොත් print කිරීම
      debugPrint("An unexpected error occurred during Google sign-in: $e");
      return null;
    }
  }

  // --- Sign Out ක්‍රියාවලිය ---
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('User signed out successfully.');
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  // --- දැනට ලොග් වී සිටින user ගේ තොරතුරු ලබාගැනීම ---
  User? get currentUser => _auth.currentUser;

  // --- Auth state එකේ (log in/out) වෙනස්කම් වලට සවන් දීම ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
