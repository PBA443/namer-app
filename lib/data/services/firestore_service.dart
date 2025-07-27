import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // debugPrint සඳහා

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // --- User කෙනෙක්ගේ Role එක Database එකේ Save කිරීම ---
  Future<void> createUserProfile({
    required User user,
    required String role,
  }) async {
    try {
      await _db.collection(_usersCollection).doc(user.uid).set(
        {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ); // merge: true මගින් දැනටමත් ඇති fields overwrite නොකරයි
    } catch (e) {
      debugPrint("Error creating user profile: $e");
      rethrow;
    }
  }

  // --- User කෙනෙක්ගේ profile එකක් තියෙනවද කියලා check කිරීම ---
  Future<bool> doesUserProfileExist(String uid) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint("Error checking user profile existence: $e");
      return false;
    }
  }

  // --- User කෙනෙක්ගේ සම්පූර්ණ profile data එක ලබා ගැනීම ---
  // මෙය AuthGate එකට user ගේ role එක කියවීමට අවශ්‍ය වේ.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.data(); // Document එකේ සියලු දත්ත Map එකක් ලෙස ලබා දෙයි
      }
      return null; // Profile එකක් හමු නොවූ විට
    } catch (e) {
      debugPrint("Error getting user profile: $e");
      return null;
    }
  }

  // --- User ගේ personal information ටික Firestore එකේ update කරනවා ---
  Future<void> updateUserData({
    required String uid,
    required String firstName,
    required String lastName,
    required String nic,
    required String? gender,
    required String phoneNumber,
    required String companyName,
    required String homeLocation,
    required String officeLocation,
  }) async {
    try {
      await _db.collection(_usersCollection).doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'nic': nic,
        'gender': gender,
        'phoneNumber': phoneNumber,
        'companyName': companyName,
        'homeLocation': homeLocation,
        'officeLocation': officeLocation,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating user data: $e");
      rethrow;
    }
  }

  // --- Driver ගේ personal information ටික Firestore එකේ update කරනවා ---
  Future<void> updateDriverData({
    required String uid,
    required String firstName,
    required String lastName,
    required String nic,
    required String? gender,
    required String phoneNumber,
  }) async {
    try {
      await _db.collection(_usersCollection).doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'nic': nic,
        'gender': gender,
        'phoneNumber': phoneNumber,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating driver data: $e");
      rethrow;
    }
  }
}
