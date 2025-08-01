// ---------------------------------------------------
// FILE: lib/presentation/features/driver_panel/trip_management/screens/create_route_page.dart (අවසාන සහ නිවැරදි කේතය)
// ---------------------------------------------------
// Waypoints සහ Alternative Routes යන දෙකම ක්‍රියාත්මක වන ලෙස සකස් කර ඇත.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Only for polyline decoding
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'confirm_schedule_page.dart';

class CreateRoutePage extends StatefulWidget {
  const CreateRoutePage({super.key});

  @override
  State<CreateRoutePage> createState() => _CreateRoutePageState();
}

class _CreateRoutePageState extends State<CreateRoutePage> {
  final String _googleApiKey =
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "API_KEY_NOT_FOUND";

  GoogleMapController? _mapController;
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612),
    zoom: 12,
  );

  final Map<PolylineId, Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];

  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();

  PolylineId? _selectedPolylineId;
  String? _totalDistance;
  String? _totalDuration;
  bool _isAddingWaypoint = false;

  @override
  void dispose() {
    _startPointController.dispose();
    _endPointController.dispose();
    super.dispose();
  }

  // --- THIS FUNCTION IS NOW FIXED TO GET ALTERNATIVE ROUTES ---

  Future<void> _getDirections() async {
    if (_routePoints.length < 2) return;

    final origin =
        "${_routePoints.first.latitude},${_routePoints.first.longitude}";
    final destination =
        "${_routePoints.last.latitude},${_routePoints.last.longitude}";

    final waypoints = _routePoints.length > 2
        ? "&waypoints=${_routePoints.sublist(1, _routePoints.length - 1).map((p) => "${p.latitude},${p.longitude}").join('|')}"
        : '';

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination$waypoints&alternatives=true&key=$_googleApiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      _polylines.clear();
      final routes = data['routes'];
      for (int i = 0; i < routes.length; i++) {
        final polylineId = PolylineId('route_$i');
        final overviewPolyline = routes[i]['overview_polyline']['points'];
        final points = PolylinePoints.decodePolyline(overviewPolyline);

        final polyline = Polyline(
          polylineId: polylineId,
          points: points.map((e) => LatLng(e.latitude, e.longitude)).toList(),
          color: i == 0 ? Colors.blueAccent : Colors.grey,
          width: 5,
          zIndex: i == 0 ? 1 : 0,
          consumeTapEvents: true,
          onTap: () {
            setState(() {
              _selectedPolylineId = polylineId;
              _totalDistance = routes[i]['legs'][0]['distance']['text'];
              _totalDuration = routes[i]['legs'][0]['duration']['text'];
              _polylines.forEach((key, value) {
                _polylines[key] = value.copyWith(
                  colorParam: key == _selectedPolylineId
                      ? Colors.blueAccent
                      : Colors.grey,
                  zIndexParam: key == _selectedPolylineId ? 1 : 0,
                );
              });
            });
          },
        );

        _polylines[polylineId] = polyline;
      }

      setState(() {
        _selectedPolylineId = const PolylineId('route_0');
        _totalDistance = routes[0]['legs'][0]['distance']['text'];
        _totalDuration = routes[0]['legs'][0]['duration']['text'];
      });
    } else {
      _showErrorSnackBar("Directions error: ${data['status']}");
    }
  }

  Future<void> _onMapTapped(LatLng location) async {
    FocusScope.of(context).unfocus();
    setState(() {
      if (_isAddingWaypoint && _routePoints.length >= 2) {
        _routePoints.insert(_routePoints.length - 1, location);
        _isAddingWaypoint = false;
      } else {
        if (_routePoints.length >= 2) _routePoints.clear();
        _routePoints.add(location);
      }
      _updateMarkersAndRoute();
      _updateTextFieldsFromMap();
    });
  }

  void _updatePointOnMap(LatLng location, bool isStartPoint) {
    if (isStartPoint) {
      if (_routePoints.isEmpty) {
        _routePoints.add(location);
      } else {
        _routePoints[0] = location;
      }
    } else {
      if (_routePoints.isEmpty) {
        _routePoints.add(const LatLng(0, 0)); // Dummy start
        _routePoints.add(location);
      } else if (_routePoints.length == 1) {
        _routePoints.add(location);
      } else {
        _routePoints[_routePoints.length - 1] = location;
      }
    }
    _updateMarkersAndRoute();
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  void _updateMarkersAndRoute() {
    setState(() {
      _markers.clear();
      for (int i = 0; i < _routePoints.length; i++) {
        BitmapDescriptor icon;
        String title;
        if (i == 0) {
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
          title = 'Start Point';
        } else if (i == _routePoints.length - 1) {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          title = 'End Point';
        } else {
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          );
          title = 'Stop $i';
        }
        _markers.add(
          Marker(
            markerId: MarkerId('point_$i'),
            position: _routePoints[i],
            infoWindow: InfoWindow(title: title),
            icon: icon,
          ),
        );
      }
      if (_routePoints.length >= 2) _getDirections();
    });
  }

  Future<void> _updateTextFieldsFromMap() async {
    try {
      if (_routePoints.isNotEmpty) {
        final placemarks = await placemarkFromCoordinates(
          _routePoints.first.latitude,
          _routePoints.first.longitude,
        );
        if (placemarks.isNotEmpty) {
          _startPointController.text = _formatPlacemark(placemarks.first);
        }
      }
      if (_routePoints.length > 1) {
        final placemarks = await placemarkFromCoordinates(
          _routePoints.last.latitude,
          _routePoints.last.longitude,
        );
        if (placemarks.isNotEmpty) {
          _endPointController.text = _formatPlacemark(placemarks.first);
        }
      }
    } catch (e) {
      print("Reverse geocoding error: $e");
    }
  }

  void _clearRoute() {
    FocusScope.of(context).unfocus();
    setState(() {
      _routePoints.clear();
      _markers.clear();
      _polylines.clear();
      _selectedPolylineId = null;
      _startPointController.clear();
      _endPointController.clear();
      _totalDistance = null;
      _totalDuration = null;
      _isAddingWaypoint = false;
    });
  }

  void _approveRoute() {
    if (_selectedPolylineId == null || _routePoints.length < 2) {
      _showErrorSnackBar('Please select a valid route.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfirmSchedulePage(
          routePoints: _routePoints,
          startAddress: _startPointController.text,
          endAddress: _endPointController.text,
          distance: _totalDistance!,
          duration: _totalDuration!,
        ),
      ),
    );
  }

  String _formatPlacemark(Placemark p) => [
    p.name,
    p.street,
    p.locality,
    p.country,
  ].where((s) => s != null && s.isNotEmpty).join(', ');
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Route'),
        backgroundColor: const Color(0xFFFDD734),
        actions: [
          if (_routePoints.length >= 2)
            TextButton.icon(
              onPressed: () {
                setState(() => _isAddingWaypoint = true);
                _showErrorSnackBar('Tap on the map to add a stop.');
              },
              icon: const Icon(
                Icons.add_location_alt_outlined,
                color: Colors.black,
              ),
              label: const Text(
                'Add Stop',
                style: TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialPosition,
              markers: _markers,
              polylines: Set<Polyline>.of(_polylines.values),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (LatLng location) {
                FocusScope.of(
                  context,
                ).unfocus(); // මේ line එක අලුතින් එකතු කරන්න
                _onMapTapped(location);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            Positioned(
              top: 10,
              left: 15,
              right: 15,
              child: Card(
                elevation: 5,
                child: Column(
                  children: [
                    GooglePlaceAutoCompleteTextField(
                      textEditingController: _startPointController,
                      googleAPIKey: _googleApiKey,
                      inputDecoration: const InputDecoration(
                        hintText: "Enter start point",
                        prefixIcon: Icon(Icons.trip_origin),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 10,
                        ),
                      ),
                      getPlaceDetailWithLatLng: (p) => _updatePointOnMap(
                        LatLng(double.parse(p.lat!), double.parse(p.lng!)),
                        true,
                      ),
                      itemClick: (p) {
                        _startPointController.text = p.description ?? "";
                        FocusScope.of(context).unfocus();
                      },
                    ),
                    const Divider(height: 1),
                    GooglePlaceAutoCompleteTextField(
                      textEditingController: _endPointController,
                      googleAPIKey: _googleApiKey,
                      inputDecoration: const InputDecoration(
                        hintText: "Enter end point",
                        prefixIcon: Icon(Icons.flag),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 10,
                        ),
                      ),
                      getPlaceDetailWithLatLng: (p) => _updatePointOnMap(
                        LatLng(double.parse(p.lat!), double.parse(p.lng!)),
                        false,
                      ),
                      itemClick: (p) {
                        _endPointController.text = p.description ?? "";
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_totalDistance != null && _totalDuration != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _InfoChip(
                              icon: Icons.directions_car,
                              label: _totalDistance!,
                            ),
                            _InfoChip(
                              icon: Icons.timer_outlined,
                              label: _totalDuration!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                              onPressed: _clearRoute,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              onPressed: _approveRoute,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: Colors.blueAccent),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: Colors.grey)),
    );
  }
}
