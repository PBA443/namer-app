// ---------------------------------------------------
// FILE 4: lib/presentation/features/user_panel/booking/screens/user_trip_tracking_page.dart (වැඩිදියුණු කළ කේතය)
// ---------------------------------------------------
// Timing issues, location permissions, and route drawing logic have been fixed.
// ---------------------------------------------------
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../../../data/services/auth_service.dart';

class UserTripTrackingPage extends StatefulWidget {
  final String tripId;
  final String bookingId;
  const UserTripTrackingPage({
    super.key,
    required this.tripId,
    required this.bookingId,
  });

  @override
  State<UserTripTrackingPage> createState() => _UserTripTrackingPageState();
}

class _UserTripTrackingPageState extends State<UserTripTrackingPage> {
  IO.Socket? _socket;
  StreamSubscription<LocationData>? _locationSubscription;
  final Location _locationService = Location();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverIcon;

  Future<DocumentSnapshot>? _tripFuture;
  Map<String, dynamic>? _tripData;
  bool _areIconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tripFuture = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .get();
    _setCustomMarkerIcon();
    _connectAndListen();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _setCustomMarkerIcon() async {
    try {
      _driverIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(96, 96)),
        'assets/images/driver_icon.png',
      );
      if (mounted) {
        setState(() {
          _areIconsLoaded = true;
        });
      }
    } catch (e) {
      print(
        "WARNING: Failed to load custom driver icon. Using default. Error: $e",
      );
      if (mounted) {
        setState(() {
          _areIconsLoaded = true;
        });
      }
    }
  }

  void _connectAndListen() async {
    // Ensure location services and permission
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final websocketUrl = dotenv.env['WEBSOCKET_URL'];
    if (websocketUrl == null || websocketUrl.isEmpty) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    // Connect to WebSocket
    _socket = IO.io(
      websocketUrl,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    _socket!.onConnect((_) {
      print('✅ Connected to WebSocket server');
      // Join the trip room after connecting
      _socket!.emit('joinTripRoom', {'tripId': widget.tripId});
    });

    _socket!.onDisconnect((_) {
      print('❌ Disconnected from WebSocket server');
    });

    // For debugging all events
    _socket!.onAny((event, data) {
      print('📩 Event: $event | Data: $data');
    });

    // Listen for driver's location updates
    _socket!.on('driverLocationUpdate', (data) {
      print("🚗 Received driver location: $data");
      final lat = data['lat'];
      final lng = data['lng'];
      if (mounted && lat != null && lng != null) {
        _updateDriverMarker(LatLng(lat, lng));
      }
    });

    // Send user's location continuously
    _locationSubscription = _locationService.onLocationChanged.listen((
      location,
    ) {
      if (_socket?.connected == true) {
        final locationData = {
          'tripId': widget.tripId,
          'role': 'user',
          'userId': user.uid,
          'lat': location.latitude,
          'lng': location.longitude,
        };
        _socket!.emit('updateLocation', locationData);
      }
    });

    _socket!.connect();
  }

  void _updateDriverMarker(LatLng location) {
    if (!mounted || !_areIconsLoaded) {
      print(
        "DEBUG: Marker cannot be updated yet. Icons loaded: $_areIconsLoaded",
      );
      return;
    }
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: location,
          icon: _driverIcon ?? BitmapDescriptor.defaultMarker,
          flat: true,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(location));
  }

  void _getDirectionsAndDrawRoute(List<dynamic> routeGeoPoints) async {
    if (routeGeoPoints.length < 2 || _polylines.isNotEmpty) return;

    final List<LatLng> routePoints = routeGeoPoints
        .whereType<GeoPoint>()
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "";
    if (apiKey.isEmpty) {
      print("❌ Google Maps API key not found");
      return;
    }

    try {
      String waypointsParam = '';
      if (routePoints.length > 2) {
        final intermediate = routePoints
            .sublist(1, routePoints.length - 1)
            .map((p) => "${p.latitude},${p.longitude}")
            .join('|');
        waypointsParam = "&waypoints=optimize:true|$intermediate";
      }

      final url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${routePoints.first.latitude},${routePoints.first.longitude}"
          "&destination=${routePoints.last.latitude},${routePoints.last.longitude}"
          "$waypointsParam"
          "&key=$apiKey";

      final response = Uri.parse(url).resolveUri(Uri());
      final data = await http.get(response);
      final decoded = jsonDecode(data.body);

      if (decoded['status'] == 'OK' && decoded['routes'].isNotEmpty) {
        final route = decoded['routes'][0];
        final points = PolylinePoints.decodePolyline(
          route['overview_polyline']['points'],
        ).map((p) => LatLng(p.latitude, p.longitude)).toList();

        if (mounted) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('tripRoute'),
                points: points,
                color: Colors.blueAccent,
                width: 5,
              ),
            );

            _markers.add(
              Marker(
                markerId: const MarkerId('start'),
                position: routePoints.first,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
            );
            _markers.add(
              Marker(
                markerId: const MarkerId('end'),
                position: routePoints.last,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            );
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
                  points
                      .map((p) => p.longitude)
                      .reduce((a, b) => a < b ? a : b),
                ),
                northeast: LatLng(
                  points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
                  points
                      .map((p) => p.longitude)
                      .reduce((a, b) => a > b ? a : b),
                ),
              ),
              50.0,
            ),
          );
        }
      } else {
        print("❌ Google Directions API error: ${decoded['status']}");
      }
    } catch (e) {
      print("❌ Error fetching directions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Your Ride")),
      body: FutureBuilder<DocumentSnapshot>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text("Could not load trip details."));
          }

          _tripData = snapshot.data!.data() as Map<String, dynamic>;

          return GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(6.9271, 79.8612),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              if (mounted) {
                _mapController = controller;
                if (_tripData?['routePoints'] != null) {
                  _getDirectionsAndDrawRoute(_tripData!['routePoints']);
                }
              }
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
          );
        },
      ),
    );
  }
}
