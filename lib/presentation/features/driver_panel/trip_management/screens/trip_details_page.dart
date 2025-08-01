import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
  final Map<String, Marker> _userMarkers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverIcon;

  Future<DocumentSnapshot>? _tripFuture;
  Map<String, dynamic>? _tripData;
  bool get _isTripActive => _tripData?['status'] == 'active';
  bool _isLoading = false;
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
      if (mounted) setState(() => _areIconsLoaded = true);
    } catch (e) {
      print("Could not load custom driver icon: $e");
    }
  }

  void _listenForBookings() {
    _bookingsSubscription = FirestoreService()
        .getBookingsForTrip(widget.tripId)
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final booking = doc.data() as Map<String, dynamic>;
            print("New booking by: ${booking['userName']}");
          }
        });
  }

  Future<void> _activateTrip() async {
    setState(() => _isLoading = true);

    await FirestoreService().updateTripStatus(widget.tripId, 'active');

    final websocketUrl = dotenv.env['WEBSOCKET_URL'];
    if (websocketUrl == null || websocketUrl.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _socket = IO.io(
      websocketUrl,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    _socket!.onConnect((_) => print('Connected to WebSocket server'));
    _socket!.onDisconnect((_) => print('Disconnected from WebSocket server'));

    _socket!.on('bookedUsersLocations', (data) {
      if (data is Map &&
          data.containsKey('userId') &&
          data.containsKey('lat') &&
          data.containsKey('lng')) {
        _updateUserMarker(
          data['userId'] as String,
          LatLng(data['lat'] as double, data['lng'] as double),
        );
      }
    });

    final serviceEnabled = await _locationService.serviceEnabled() ?? false;
    if (!serviceEnabled && !(await _locationService.requestService())) {
      setState(() => _isLoading = false);
      return;
    }

    final permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied &&
        await _locationService.requestPermission() !=
            PermissionStatus.granted) {
      setState(() => _isLoading = false);
      return;
    }

    final initialLocation = await _locationService.getLocation();
    if (initialLocation.latitude != null && initialLocation.longitude != null) {
      _updateDriverMarker(initialLocation);
    }

    _locationSubscription = _locationService.onLocationChanged.listen((
      location,
    ) {
      _updateDriverMarker(location);
      _socket?.emit('updateLocation', {
        'tripId': widget.tripId,
        'lat': location.latitude,
        'lng': location.longitude,
      });
    });

    setState(() {
      _tripData?['status'] = 'active';
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Trip is now active and tracking has started!"),
        ),
      );
    }
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

  void _updateUserMarker(String userId, LatLng location) {
    if (!mounted) return;

    setState(() {
      _userMarkers['user_$userId'] = Marker(
        markerId: MarkerId('user_$userId'),
        position: location,
        infoWindow: InfoWindow(title: 'User: $userId'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      );
    });
  }

  Future<void> _deactivateTrip({bool isDisposing = false}) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    if (!isDisposing) {
      await FirestoreService().updateTripStatus(widget.tripId, 'completed');
      setState(() => _tripData?['status'] = 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip has been completed!")),
        );
      }
    }
  }

  Future<void> _drawRoute(List<dynamic> rawRoutePoints) async {
    if (rawRoutePoints.isEmpty) return;

    // Convert Firestore GeoPoints to LatLng
    final waypoints = rawRoutePoints
        .whereType<GeoPoint>()
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    if (waypoints.length < 2) return;

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "";
    if (apiKey.isEmpty) {
      print("Google Maps API key not found");
      return;
    }

    try {
      // Build the waypoints parameter for the API
      String waypointsParam = '';
      if (waypoints.length > 2) {
        final intermediate = waypoints
            .sublist(1, waypoints.length - 1)
            .map((p) => "${p.latitude},${p.longitude}")
            .join('|');
        waypointsParam = "&waypoints=optimize:true|$intermediate";
      }

      final url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${waypoints.first.latitude},${waypoints.first.longitude}"
          "&destination=${waypoints.last.latitude},${waypoints.last.longitude}"
          "$waypointsParam"
          "&key=$apiKey";

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final points = PolylinePoints.decodePolyline(
          route['overview_polyline']['points'],
        ).map((p) => LatLng(p.latitude, p.longitude)).toList();

        setState(() {
          _polylines.clear();
          _markers.removeWhere((m) => m.markerId.value.startsWith('route_'));

          // Add the proper road route
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('road_route'),
              points: points,
              color: Colors.blueAccent,
              width: 5,
            ),
          );

          // Add markers for waypoints
          for (int i = 0; i < waypoints.length; i++) {
            _markers.add(
              Marker(
                markerId: MarkerId('route_point_$i'),
                position: waypoints[i],
                icon: i == 0
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      )
                    : i == waypoints.length - 1
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      )
                    : BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                infoWindow: InfoWindow(
                  title: i == 0
                      ? 'Start'
                      : i == waypoints.length - 1
                      ? 'End'
                      : 'Stop ${i}',
                ),
              ),
            );
          }

          _fitRouteToScreen(points);
        });
      } else {
        print("Directions API error: ${data['status']}");
        // Fallback to straight line if API fails
        _drawStraightLineRoute(waypoints);
      }
    } catch (e) {
      print("Error getting directions: $e");
      _drawStraightLineRoute(waypoints);
    }
  }

  void _drawStraightLineRoute(List<LatLng> points) {
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('fallback_route'),
          points: points,
          color: Colors.grey,
          width: 3,
        ),
      );
      _fitRouteToScreen(points);
    });
  }

  void _fitRouteToScreen(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    LatLngBounds bounds = _boundsFromLatLngList(points);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        x1 = x1! > latLng.latitude ? x1 : latLng.latitude;
        x0 = x0 < latLng.latitude ? x0 : latLng.latitude;
        y1 = y1! > latLng.longitude ? y1 : latLng.longitude;
        y0 = y0! < latLng.longitude ? y0 : latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
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
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("Trip not found or error loading data."),
            );
          }

          _tripData ??= snapshot.data!.data() as Map<String, dynamic>;
          if (_tripData?['routePoints'] != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _drawRoute(_tripData!['routePoints']);
            });
          }

          final startTime = (_tripData!['startTime'] as Timestamp).toDate();

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(6.9271, 79.8612),
                  zoom: 12,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: {..._markers, ..._userMarkers.values},
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
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
                          'Scheduled for: ${DateFormat('MMM d, yyyy hh:mm a').format(startTime)}',
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: _isTripActive
                              ? ElevatedButton.icon(
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: const Text('END TRIP'),
                                  onPressed: _isLoading
                                      ? null
                                      : () => _deactivateTrip(),
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
                                  label: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text('ACTIVATE TRIP'),
                                  onPressed: _isLoading ? null : _activateTrip,
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
