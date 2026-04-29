import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/event.dart';

class EventsMap extends StatefulWidget {
  final List<Event> events;
  final Function(Event) onEventTapped;

  const EventsMap({
    super.key,
    required this.events,
    required this.onEventTapped,
  });

  @override
  State<EventsMap> createState() => _EventsMapState();
}

class _EventsMapState extends State<EventsMap> {
  static const _fiveMilesInMeters = 8046.72;
  late final Future<LatLng?> _currentLocationFuture;

  @override
  void initState() {
    super.initState();
    _currentLocationFuture = _getCurrentLocation();
  }

  Future<LatLng?> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final mappable = widget.events
        .where((e) => e.latitude != null && e.longitude != null)
        .toList();

    return FutureBuilder<LatLng?>(
      future: _currentLocationFuture,
      builder: (context, snapshot) {
        final currentLocation = snapshot.data;
        if (mappable.isEmpty && currentLocation == null) {
          return const Center(
            child: Text(
              'No mappable events yet. Use a real address when posting.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        }

        final markers = mappable
            .map(
              (event) => Marker(
                markerId: MarkerId(event.id),
                position: LatLng(event.latitude!, event.longitude!),
                infoWindow: InfoWindow(
                  title: event.title,
                  snippet: event.location,
                  onTap: () => widget.onEventTapped(event),
                ),
                onTap: () => widget.onEventTapped(event),
              ),
            )
            .toSet();

        if (currentLocation != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('current-location'),
              position: currentLocation,
              infoWindow: const InfoWindow(title: 'You are here'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }

        final circles = <Circle>{};
        if (currentLocation != null) {
          circles.add(
            Circle(
              circleId: const CircleId('five-mile-radius'),
              center: currentLocation,
              radius: _fiveMilesInMeters,
              strokeColor: Colors.blueAccent,
              strokeWidth: 2,
              fillColor: Colors.blueAccent.withOpacity(0.15),
            ),
          );
        }

        final target = currentLocation ??
            LatLng(mappable.first.latitude!, mappable.first.longitude!);

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: target,
            zoom: 14,
          ),
          markers: markers,
          circles: circles,
          myLocationEnabled: currentLocation != null,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: false,
        );
      },
    );
  }
}
