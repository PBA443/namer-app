// ---------------------------------------------------
// FILE: lib/presentation/features/driver_panel/dashboard/screens/driver_dashboard_page.dart (Updated File)
// ---------------------------------------------------
// The dashboard now checks if a driver has existing trips and changes the UI accordingly.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../../../../../data/services/auth_service.dart';
import '../../../../../data/services/firestore_service.dart'; // Import FirestoreService
import '../../../auth/screens/auth_gate.dart';
import '../../trip_management/screens/create_route_page.dart';
import '../../trip_management/screens/my_trips_page.dart';

// Convert to a StatefulWidget to fetch data
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  final user = AuthService().currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDD734),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 30),
          onPressed: () {
            // TODO: Open navigation drawer
          },
        ),
        title: Text(
          'Welcome, ${user?.displayName?.split(' ').first ?? 'Driver'}!',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black, size: 30),
            onPressed: () async {
              // Simple logout confirmation
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await AuthService().signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // Use a StreamBuilder to check for trips in real-time
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getDriverTrips(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data."));
          }

          // Check if the driver has any trips
          final bool hasTrips =
              snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.drive_eta_rounded,
                    size: 150,
                    color: Color(0xFFFDD734),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    // Show a different message for new drivers
                    hasTrips
                        ? 'What would you like to do?'
                        : 'Welcome! Let\'s publish your first trip.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // "Publish a New Trip" Button (Always visible)
                  TextButton.icon(
                    icon: const Icon(
                      Icons.add_road_rounded,
                      color: Color(0xFFF0C414),
                    ),
                    label: Text(
                      // Change text for new drivers
                      hasTrips
                          ? 'Publish a New Trip'
                          : 'Publish Your First Trip',
                      style: const TextStyle(
                        color: Color(0xFFF0C414),
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFF0C414),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateRoutePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- "View My Trips" Button (Only show if the driver has trips) ---
                  if (hasTrips)
                    TextButton.icon(
                      icon: const Icon(
                        Icons.list_alt_rounded,
                        color: Colors.black54,
                      ),
                      label: const Text(
                        'View My Scheduled Trips',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MyTripsPage(),
                          ),
                        );
                      },
                    ),
                  const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
