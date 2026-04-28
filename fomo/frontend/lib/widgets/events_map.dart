import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/event.dart';

class EventsMap extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEventTapped;

  const EventsMap({
    super.key,
    required this.events,
    required this.onEventTapped,
  });

  @override
  Widget build(BuildContext context) {
    final mappable = events
        .where((e) => e.latitude != null && e.longitude != null)
        .toList();

    if (mappable.isEmpty) {
      return const Center(
        child: Text(
          'No mappable events yet. Use a real address when posting.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    final first = mappable.first;
    final markers = mappable
        .map(
          (event) => Marker(
            markerId: MarkerId(event.id),
            position: LatLng(event.latitude!, event.longitude!),
            infoWindow: InfoWindow(
              title: event.title,
              snippet: event.location,
              onTap: () => onEventTapped(event),
            ),
            onTap: () => onEventTapped(event),
          ),
        )
        .toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(first.latitude!, first.longitude!),
        zoom: 12,
      ),
      markers: markers,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
