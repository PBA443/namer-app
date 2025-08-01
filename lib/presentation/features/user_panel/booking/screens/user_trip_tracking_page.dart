// ---------------------------------------------------
// FILE 4: lib/presentation/features/user_panel/booking/screens/user_trip_tracking_page.dart (New File)
// ---------------------------------------------------
// This is the new page for the user to track the driver in real-time.
// ---------------------------------------------------
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
  BitmapDescriptor? _driverIcon;

  @override
  void initState() {
    super.initState();
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
    _driverIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/driver_icon.png',
    );
  }

  void _connectAndListen() async {
    // Connect to WebSocket
    final websocketUrl = dotenv.env['WEBSOCKET_URL'];
    if (websocketUrl == null) return;
    _socket = IO.io(
      websocketUrl,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    // Listen for driver's location updates
    _socket!.on('driverLocationUpdate_${widget.tripId}', (data) {
      print("Received driver location: $data");
      final lat = data['lat'];
      final lng = data['lng'];
      if (lat != null && lng != null) {
        _updateDriverMarker(LatLng(lat, lng));
      }
    });

    // Start sending user's location
    // (This requires the same location permission logic as the driver's page)
    _locationSubscription = _locationService.onLocationChanged.listen((
      location,
    ) {
      final user = AuthService().currentUser;
      if (user == null) return;

      final locationData = {
        'bookingId': widget.bookingId,
        'userId': user.uid,
        'lat': location.latitude,
        'lng': location.longitude,
      };
      _socket?.emit('userLocationUpdate', locationData);
    });
  }

  void _updateDriverMarker(LatLng location) {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Your Ride")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.9271, 79.8612),
          zoom: 12,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        myLocationEnabled: true,
      ),
    );
  }
}
