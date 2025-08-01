import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  final String _tripsCollection = 'trips';
  final String _bookingsCollection = 'bookings';

  // ------------------------ USER SECTION ------------------------

  Future<void> createUserProfile({
    required User user,
    required String role,
  }) async {
    try {
      await _db.collection(_usersCollection).doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Error creating user profile: $e");
      rethrow;
    }
  }

  Future<bool> doesUserProfileExist(String uid) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint("🔥 Error checking user profile existence: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint("🔥 Error fetching user profile: $e");
      return null;
    }
  }

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
      await _db.collection(_usersCollection).doc(uid).update({
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
      });
    } catch (e) {
      debugPrint("🔥 Error updating user data: $e");
      rethrow;
    }
  }

  Future<void> updateDriverData({
    required String uid,
    required String firstName,
    required String lastName,
    required String nic,
    required String? gender,
    required String phoneNumber,
  }) async {
    try {
      await _db.collection(_usersCollection).doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'nic': nic,
        'gender': gender,
        'phoneNumber': phoneNumber,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Error updating driver data: $e");
      rethrow;
    }
  }

  // ------------------------ TRIP SECTION ------------------------

  Future<void> createTrip({
    required User driver,
    required List<LatLng> routePoints,
    required String startAddress,
    required String endAddress,
    required String distance,
    required String duration,
    required DateTime startTime,
    required DateTime endTime,
    String? recurringId,
  }) async {
    try {
      await _db.collection(_tripsCollection).add({
        'driverId': driver.uid,
        'driverName': driver.displayName,
        'driverPhotoUrl': driver.photoURL,
        'startAddress': startAddress,
        'endAddress': endAddress,
        'distance': distance,
        'duration': duration,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'routePoints': routePoints
            .map((p) => GeoPoint(p.latitude, p.longitude))
            .toList(),
        'status': 'pending',
        'recurringId': recurringId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Error creating trip: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getDriverTrips(String driverId) {
    try {
      return _db
          .collection(_tripsCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('startTime', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint("🔥 Error fetching driver trips: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getAvailableTrips() {
    try {
      return _db
          .collection(_tripsCollection)
          .where('status', isEqualTo: 'active')
          .where('startTime', isGreaterThan: Timestamp.now())
          .orderBy('startTime')
          .snapshots();
    } catch (e) {
      debugPrint("🔥 Error fetching available trips: $e");
      rethrow;
    }
  }

  Future<void> updateTripStatus(String tripId, String status) async {
    try {
      await _db.collection(_tripsCollection).doc(tripId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Error updating trip status: $e");
      rethrow;
    }
  }

  // ------------------------ BOOKING SECTION ------------------------

  Future<String> createBooking({
    required String tripId,
    required String driverId,
    required User user,
  }) async {
    try {
      final bookingRef = await _db.collection(_bookingsCollection).add({
        'tripId': tripId,
        'driverId': driverId,
        'userId': user.uid,
        'userName': user.displayName,
        'userPhotoUrl': user.photoURL,
        'status': 'booked',
        'bookedAt': FieldValue.serverTimestamp(),
      });
      return bookingRef.id;
    } catch (e) {
      debugPrint("🔥 Error creating booking: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getBookingsForTrip(String tripId) {
    return _db
        .collection(_bookingsCollection)
        .where('tripId', isEqualTo: tripId)
        .where('status', isEqualTo: 'booked')
        .snapshots();
  }
}
