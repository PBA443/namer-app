import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../../data/services/auth_service.dart';
import '../../../../../data/services/firestore_service.dart';
import 'create_route_page.dart';
import 'trip_details_page.dart';

class MyTripsPage extends StatelessWidget {
  const MyTripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Scheduled Trips"),
        backgroundColor: const Color(0xFFFDD734),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateRoutePage()),
          );
        },
        label: const Text("Schedule New Trip"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFF07A0C),
      ),
      body: user == null
          ? const Center(child: Text("Please log in to see your trips."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().getDriverTrips(user.uid),
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
                      "You have no scheduled trips.\nTap the '+' button to create one!",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final trips = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final doc = trips[index];
                    final trip = doc.data() as Map<String, dynamic>;
                    final tripId = doc.id;
                    final startTime = (trip['startTime'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.directions_car,
                          color: trip['status'] == 'active'
                              ? Colors.green
                              : const Color(0xFFF07A0C),
                        ),
                        title: Text(
                          'From: ${trip['startAddress']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To: ${trip['endAddress']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'MMM d, yyyy  hh:mm a',
                              ).format(startTime),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Text(
                          trip['status'] ?? 'N/A',
                          style: TextStyle(
                            color: trip['status'] == 'active'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  TripDetailsPage(tripId: tripId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
