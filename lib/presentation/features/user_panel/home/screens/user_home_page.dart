import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Location package
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google Maps package
import '../../booking/screens/route_selection_page.dart'; // Import the new page
import '../../../auth/screens/auth_gate.dart'; // Import AuthGate to navigate after logout
import '../../../../../data/services/auth_service.dart'; // Import AuthService for logout functionality

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  bool _isFetchingLocation = false;

  // --- Function to get the user's location ---
  Future<void> _getCurrentLocationAndNavigate() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      // 1. Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // If no permission, ask the user
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // If the user denies permission, show a message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          setState(() {
            _isFetchingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // If the user has permanently denied permission, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }

      // 2. If permission is granted, get the location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Create a LatLng object
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      // 4. Navigate to the RouteSelectionPage
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              RouteSelectionPage(initialLocation: userLocation),
        ),
      );
    } catch (e) {
      print("Error fetching location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get your location. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  // --- Function to show the logout confirmation dialog ---
  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[Text('Are you sure you want to log out?')],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                await AuthService().signOut();
                if (mounted) {
                  // Navigate back to the AuthGate, which will then show the SignInPage
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 30),
          onPressed: () {},
        ),
        // --- Logout Button ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black, size: 30),
            onPressed:
                _showLogoutConfirmationDialog, // Call the confirmation dialog
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.local_taxi_outlined,
              size: 150,
              color: Color(0xFFFDD734),
            ),
            const SizedBox(height: 40),
            const Text(
              'Hi, nice to meet you!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose your pickup location',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 48),

            // "Use current location" button
            _isFetchingLocation
                ? const Center(child: CircularProgressIndicator())
                : OutlinedButton.icon(
                    onPressed:
                        _getCurrentLocationAndNavigate, // Call the new function
                    icon: const Icon(Icons.my_location_rounded, size: 20),
                    label: const Text('Use current location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB59400),
                      side: const BorderSide(
                        color: Color(0xFFFDD734),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
            const SizedBox(height: 20),

            // "Select it manually" button
            TextButton(
              onPressed: () {
                // Navigate to the route selection page with a default central location
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RouteSelectionPage(),
                  ),
                );
              },
              child: const Text(
                'Select it manually',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
