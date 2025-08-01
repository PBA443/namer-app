// ---------------------------------------------------
// FILE 2: lib/presentation/features/booking/screens/available_trips_page.dart (Updated File)
// ---------------------------------------------------
// The "Book Now" button now creates a booking in Firestore and
// navigates to the new UserTripTrackingPage.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../../data/services/auth_service.dart';
import '../../../../../data/services/firestore_service.dart';
import 'user_trip_tracking_page.dart';

class AvailableTripsPage extends StatelessWidget {
  final LatLng pickupLocation;
  final LatLng dropoffLocation;

  const AvailableTripsPage({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Trips"),
        backgroundColor: const Color(0xFFFDD734),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getAvailableTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong!"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Sorry, no trips are available for this route right now.",
                textAlign: TextAlign.center,
              ),
            );
          }

          final trips = snapshot.data!.docs;

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index].data() as Map<String, dynamic>;
              final tripId = trips[index].id;
              final startTime = (trip['startTime'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              trip['driverPhotoUrl'] ??
                                  'https://placehold.co/100x100/FDD734/000000?text=Driver',
                            ),
                            radius: 25,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              trip['driverName'] ?? 'Driver',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.trip_origin,
                        "From",
                        trip['startAddress'],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.flag, "To", trip['endAddress']),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today,
                        "Date",
                        DateFormat('MMM d, yyyy').format(startTime),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.access_time_filled,
                        "Time",
                        DateFormat('hh:mm a').format(startTime),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please log in to book."),
                                ),
                              );
                              return;
                            }
                            try {
                              final bookingId = await FirestoreService()
                                  .createBooking(
                                    tripId: tripId,
                                    driverId: trip['driverId'],
                                    user: currentUser,
                                  );
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserTripTrackingPage(
                                      tripId: tripId,
                                      bookingId: bookingId,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Booking failed. Please try again.",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF07A0C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Book Now",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text('$title: $subtitle', overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
