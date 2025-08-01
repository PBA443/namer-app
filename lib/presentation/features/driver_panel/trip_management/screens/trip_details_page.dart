// ---------------------------------------------------
// FILE 3: lib/presentation/features/driver_panel/trip_management/screens/trip_details_page.dart (Updated File)
// ---------------------------------------------------
// This page now listens for new bookings and displays user markers on the map.
// ---------------------------------------------------
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../../../data/services/firestore_service.dart';

class TripDetailsPage extends StatefulWidget {
  final String tripId;
  const TripDetailsPage({super.key, required this.tripId});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  IO.Socket? _socket;
  StreamSubscription<LocationData>? _locationSubscription;
  final Location _locationService = Location();
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverIcon;

  Future<DocumentSnapshot>? _tripFuture;
  Map<String, dynamic>? _tripData;
  bool get _isTripActive => _tripData?['status'] == 'active';

  bool _areIconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tripFuture = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .get();
    _setCustomMarkerIcon();
    _listenForBookings();
  }

  @override
  void dispose() {
    _deactivateTrip(isDisposing: true);
    _bookingsSubscription?.cancel();
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
        "WARNING: Could not load custom driver icon. Using default. Error: $e",
      );
    }
  }

  void _listenForBookings() {
    _bookingsSubscription = FirestoreService()
        .getBookingsForTrip(widget.tripId)
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final booking = doc.data() as Map<String, dynamic>;
            print("New booking by: ${booking['userName']}");
            setState(() {
              _markers.add(
                Marker(
                  markerId: MarkerId('user_${booking['userId']}'),
                  position: const LatLng(6.9022, 79.8612), // Placeholder
                  infoWindow: InfoWindow(title: booking['userName']),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueViolet,
                  ),
                ),
              );
            });
          }
        });
  }

  Future<void> _activateTrip() async {
    await FirestoreService().updateTripStatus(widget.tripId, 'active');

    final websocketUrl = dotenv.env['WEBSOCKET_URL'];
    if (websocketUrl == null || websocketUrl.isEmpty) return;

    _socket = IO.io(
      websocketUrl,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    _socket!.onConnect((_) => print('Connected to WebSocket server'));
    _socket!.onDisconnect((_) => print('Disconnected from WebSocket server'));
    _socket!.on('bookedUsersLocations', (data) {
      print('Received user locations: $data');
    });

    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled)
      serviceEnabled = await _locationService.requestService();
    if (!serviceEnabled) return;

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    var initialLocation = await _locationService.getLocation();
    _updateDriverMarker(initialLocation);

    _locationSubscription = _locationService.onLocationChanged.listen((
      currentLocation,
    ) {
      _updateDriverMarker(currentLocation);
      final locationData = {
        'tripId': widget.tripId,
        'lat': currentLocation.latitude,
        'lng': currentLocation.longitude,
      };
      _socket?.emit('updateLocation', locationData);
    });

    setState(() {
      _tripData?['status'] = 'active';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Trip is now active and tracking has started!"),
      ),
    );
  }

  void _updateDriverMarker(LocationData locationData) {
    if (!mounted || !_areIconsLoaded) return;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(locationData.latitude!, locationData.longitude!),
          icon: _driverIcon!,
          rotation: locationData.heading ?? 0.0,
          anchor: const Offset(0.5, 0.5),
          zIndex: 2,
          flat: true,
        ),
      );
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(locationData.latitude!, locationData.longitude!),
      ),
    );
  }

  Future<void> _deactivateTrip({bool isDisposing = false}) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    if (!isDisposing) {
      await FirestoreService().updateTripStatus(widget.tripId, 'completed');
      setState(() {
        _tripData?['status'] = 'completed';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Trip has been completed!")));
    }
  }

  void _getDirectionsAndDrawRoute(Map<String, dynamic> tripData) async {
    final dynamic rawRoutePoints = tripData['routePoints'];
    if (rawRoutePoints == null ||
        rawRoutePoints is! List ||
        rawRoutePoints.isEmpty)
      return;
    if (_polylines.isNotEmpty) return;

    final List<LatLng> points = [];
    for (var p in rawRoutePoints) {
      if (p is GeoPoint) {
        points.add(LatLng(p.latitude, p.longitude));
      }
    }
    if (points.length < 2) return;

    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "";
    final PolylinePoints polylinePoints = PolylinePoints(apiKey: apiKey);

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(points.first.latitude, points.first.longitude),
        destination: PointLatLng(points.last.latitude, points.last.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      if (mounted) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('tripRoute'),
              points: polylineCoordinates,
              color: Colors.blueAccent,
              width: 5,
            ),
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('start'),
              position: points.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('end'),
              position: points.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        });

        if (_mapController != null) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      polylineCoordinates
                          .map((p) => p.latitude)
                          .reduce((a, b) => a < b ? a : b),
                      polylineCoordinates
                          .map((p) => p.longitude)
                          .reduce((a, b) => a < b ? a : b),
                    ),
                    northeast: LatLng(
                      polylineCoordinates
                          .map((p) => p.latitude)
                          .reduce((a, b) => a > b ? a : b),
                      polylineCoordinates
                          .map((p) => p.longitude)
                          .reduce((a, b) => a > b ? a : b),
                    ),
                  ),
                  50.0,
                ),
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Details"),
        backgroundColor: const Color(0xFFFDD734),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Trip not found."));
          }

          if (_tripData == null) {
            _tripData = snapshot.data!.data() as Map<String, dynamic>;
          }
          final startTime = (_tripData!['startTime'] as Timestamp).toDate();

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(6.9271, 79.8612),
                  zoom: 12,
                ),
                onMapCreated: (controller) {
                  if (mounted) {
                    _mapController = controller;
                    _getDirectionsAndDrawRoute(_tripData!);
                  }
                },
                markers: _markers,
                polylines: _polylines,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From: ${_tripData!['startAddress'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'To: ${_tripData!['endAddress'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        Text(
                          'Scheduled for: ${DateFormat('MMM d, yyyy  hh:mm a').format(startTime)}',
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: _isTripActive
                              ? ElevatedButton.icon(
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: const Text('END TRIP'),
                                  onPressed: () => _deactivateTrip(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('ACTIVATE TRIP'),
                                  onPressed: _activateTrip,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
