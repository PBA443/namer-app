// ---------------------------------------------------
// FILE 3: lib/presentation/features/driver_panel/trip_management/screens/confirm_schedule_page.dart (Updated File)
// ---------------------------------------------------
// This page now includes weekly scheduling options.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../../data/services/auth_service.dart';
import '../../../../../data/services/firestore_service.dart';
import 'my_trips_page.dart';

class ConfirmSchedulePage extends StatefulWidget {
  final List<LatLng> routePoints;
  final String startAddress;
  final String endAddress;
  final String distance;
  final String duration;

  const ConfirmSchedulePage({
    super.key,
    required this.routePoints,
    required this.startAddress,
    required this.endAddress,
    required this.distance,
    required this.duration,
  });

  @override
  State<ConfirmSchedulePage> createState() => _ConfirmSchedulePageState();
}

class _ConfirmSchedulePageState extends State<ConfirmSchedulePage> {
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isLoading = false;

  bool _repeatsWeekly = false;
  DateTime? _endDate;
  final Map<int, bool> _selectedWeekdays = {
    DateTime.monday: false,
    DateTime.tuesday: false,
    DateTime.wednesday: false,
    DateTime.thursday: false,
    DateTime.friday: false,
    DateTime.saturday: false,
    DateTime.sunday: false,
  };

  @override
  void initState() {
    super.initState();
    _setStartTime(DateTime.now().add(const Duration(hours: 1)));
    _endDate = DateTime.now().add(const Duration(days: 30));
  }

  void _calculateEndTime(DateTime startTime) {
    final durationValue =
        int.tryParse(widget.duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _endTime = startTime.add(Duration(minutes: durationValue));
    });
  }

  void _setStartTime(DateTime newStartTime) {
    setState(() {
      _startTime = newStartTime;
    });
    _calculateEndTime(newStartTime);
  }

  Future<void> _pickDateTime(bool isStartTime) async {
    final initialDate = (isStartTime ? _startTime : _endTime) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;
    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (isStartTime) {
      _setStartTime(newDateTime);
    } else {
      setState(() {
        _endTime = newDateTime;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate!,
      firstDate: _startTime!,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null && pickedDate != _endDate) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  Future<void> _publishTrip() async {
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: You are not logged in.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_repeatsWeekly) {
        final recurringId = const Uuid().v4();
        final selectedDays = _selectedWeekdays.entries
            .where((day) => day.value)
            .map((day) => day.key)
            .toList();
        if (selectedDays.isEmpty) {
          throw Exception("Please select at least one day to repeat.");
        }
        List<Future<void>> tripFutures = [];
        DateTime currentDate = _startTime!;
        while (currentDate.isBefore(_endDate!.add(const Duration(days: 1)))) {
          if (selectedDays.contains(currentDate.weekday)) {
            final newStartTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              _startTime!.hour,
              _startTime!.minute,
            );
            final newEndTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              _endTime!.hour,
              _endTime!.minute,
            );
            tripFutures.add(
              FirestoreService().createTrip(
                driver: user,
                routePoints: widget.routePoints,
                startAddress: widget.startAddress,
                endAddress: widget.endAddress,
                distance: widget.distance,
                duration: widget.duration,
                startTime: newStartTime,
                endTime: newEndTime,
                recurringId: recurringId,
              ),
            );
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
        await Future.wait(tripFutures);
      } else {
        await FirestoreService().createTrip(
          driver: user,
          routePoints: widget.routePoints,
          startAddress: widget.startAddress,
          endAddress: widget.endAddress,
          distance: widget.distance,
          duration: widget.duration,
          startTime: _startTime!,
          endTime: _endTime!,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyTripsPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip(s) published successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to publish trip: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Schedule'),
        backgroundColor: const Color(0xFFFDD734),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Route Summary",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRouteInfoCard(),
                  const SizedBox(height: 32),
                  const Text(
                    "Set Your Schedule",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTimePickerCard(
                    "Start Time",
                    _startTime,
                    () => _pickDateTime(true),
                  ),
                  const SizedBox(height: 16),
                  _buildTimePickerCard(
                    "End Time (Adjustable)",
                    _endTime,
                    () => _pickDateTime(false),
                  ),
                  const SizedBox(height: 24),
                  _buildRepeatSection(),
                  if (_repeatsWeekly) ...[
                    const SizedBox(height: 16),
                    _buildWeekdaySelector(),
                    const SizedBox(height: 16),
                    _buildTimePickerCard(
                      "Repeat Until",
                      _endDate,
                      _pickEndDate,
                      icon: Icons.event_busy,
                    ),
                  ],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.publish),
                      label: const Text('Publish Trip'),
                      onPressed: _publishTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildRouteInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.trip_origin, "From", widget.startAddress),
            const Divider(height: 24),
            _buildInfoRow(Icons.flag, "To", widget.endAddress),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(Icons.directions_car, widget.distance),
                _buildInfoChip(Icons.timer_outlined, widget.duration),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerCard(
    String title,
    DateTime? time,
    VoidCallback onTap, {
    IconData icon = Icons.calendar_today,
  }) {
    final formattedTime = time != null
        ? DateFormat('MMM d, yyyy  hh:mm a').format(time)
        : 'Tap to select';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(
          formattedTime,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.edit),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, color: Colors.blueAccent, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRepeatSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: const Text("Repeat Weekly"),
        value: _repeatsWeekly,
        onChanged: (bool value) {
          setState(() {
            _repeatsWeekly = value;
          });
        },
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    final days = {
      "Mon": DateTime.monday,
      "Tue": DateTime.tuesday,
      "Wed": DateTime.wednesday,
      "Thu": DateTime.thursday,
      "Fri": DateTime.friday,
      "Sat": DateTime.saturday,
      "Sun": DateTime.sunday,
    };
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.entries.map((day) {
            final isSelected = _selectedWeekdays[day.value] ?? false;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedWeekdays[day.value] = !isSelected;
                });
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                child: Text(
                  day.key,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
