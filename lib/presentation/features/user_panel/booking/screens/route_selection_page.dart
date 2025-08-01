// ---------------------------------------------------
// FILE 1: lib/presentation/features/booking/screens/route_selection_page.dart (වැඩිදියුණු කළ කේතය)
// ---------------------------------------------------
// Text field එකෙන් පිට tap කළ විට, keyboard එක hide වන ලෙස සකස් කර ඇත.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'available_trips_page.dart';

class RouteSelectionPage extends StatefulWidget {
  // HomePage එකෙන් එවන user ගේ location එක (optional)
  final LatLng? initialLocation;

  const RouteSelectionPage({super.key, this.initialLocation});

  @override
  State<RouteSelectionPage> createState() => _RouteSelectionPageState();
}

class _RouteSelectionPageState extends State<RouteSelectionPage> {
  final String _googleApiKey =
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "API_KEY_NOT_FOUND";

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropOffController = TextEditingController();

  LatLng? _pickupLocation;
  LatLng? _dropOffLocation;

  @override
  void initState() {
    super.initState();
    // "Use current location" click කරලා ආවොත්, ඒ location එක set කරනවා
    if (widget.initialLocation != null) {
      _setPointOnMap(widget.initialLocation!, isPickup: true);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropOffController.dispose();
    super.dispose();
  }

  // Map එකේ point එකක් set කරලා, address එක auto-fill කරනවා
  Future<void> _setPointOnMap(LatLng location, {required bool isPickup}) async {
    String address = "Unknown Location";
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = "${p.name}, ${p.street}, ${p.locality}";
      }
    } catch (e) {
      print("Error getting address: $e");
    }

    setState(() {
      if (isPickup) {
        _pickupLocation = location;
        _pickupController.text = address;
        _markers.removeWhere((m) => m.markerId.value == 'pickup');
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: location,
            infoWindow: const InfoWindow(title: 'Pickup Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      } else {
        _dropOffLocation = location;
        _dropOffController.text = address;
        _markers.removeWhere((m) => m.markerId.value == 'dropoff');
        _markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: location,
            infoWindow: const InfoWindow(title: 'Drop-off Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      if (_pickupLocation != null && _dropOffLocation != null) {
        _getDirections();
      }
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  // Route එක අඳිනවා
  Future<void> _getDirections() async {
    if (_pickupLocation == null || _dropOffLocation == null) return;

    _polylines.clear();
    PolylinePoints polylinePoints = PolylinePoints(apiKey: _googleApiKey);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(
          _pickupLocation!.latitude,
          _pickupLocation!.longitude,
        ),
        destination: PointLatLng(
          _dropOffLocation!.latitude,
          _dropOffLocation!.longitude,
        ),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blueAccent,
            width: 6,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Route'),
        backgroundColor: const Color(0xFFFDD734),
      ),
      // --- KEYBOARD HIDE FIX ---
      // GestureDetector එකෙන් සම්පූර්ණ body එකම wrap කරනවා.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // <-- important
        onTap: () {
          // Text field එකෙන් පිට tap කළ විට, keyboard එක hide කරනවා.
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: widget.initialLocation ?? const LatLng(6.9271, 79.8612),
                zoom: 16.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            // Search fields සහ button එක තියෙන bottom sheet එක
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.7,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pickup Location Search Field
                      GooglePlaceAutoCompleteTextField(
                        textEditingController: _pickupController,
                        googleAPIKey: _googleApiKey,
                        inputDecoration: const InputDecoration(
                          hintText: "Enter pickup location",
                          prefixIcon: Icon(Icons.trip_origin),
                        ),
                        debounceTime: 400,
                        isLatLngRequired: true,
                        getPlaceDetailWithLatLng: (p) => _setPointOnMap(
                          LatLng(double.parse(p.lat!), double.parse(p.lng!)),
                          isPickup: true,
                        ),
                        itemClick: (p) {
                          _pickupController.text = p.description ?? "";
                          FocusScope.of(
                            context,
                          ).unfocus(); // Suggestion එකක් select කළාමත් keyboard එක hide කරනවා
                        },
                      ),
                      const SizedBox(height: 16),

                      // Drop-off Location Search Field
                      GooglePlaceAutoCompleteTextField(
                        textEditingController: _dropOffController,
                        googleAPIKey: _googleApiKey,
                        inputDecoration: const InputDecoration(
                          hintText: "Enter drop-off location",
                          prefixIcon: Icon(Icons.flag),
                        ),
                        debounceTime: 400,
                        isLatLngRequired: true,
                        getPlaceDetailWithLatLng: (p) => _setPointOnMap(
                          LatLng(double.parse(p.lat!), double.parse(p.lng!)),
                          isPickup: false,
                        ),
                        itemClick: (p) {
                          _dropOffController.text = p.description ?? "";
                          FocusScope.of(
                            context,
                          ).unfocus(); // Suggestion එකක් select කළාමත් keyboard එක hide කරනවා
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_pickupLocation != null &&
                              _dropOffLocation != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AvailableTripsPage(
                                  pickupLocation: _pickupLocation!,
                                  dropoffLocation: _dropOffLocation!,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select both pickup and drop-off locations.',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF07A0C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Find Rides'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
