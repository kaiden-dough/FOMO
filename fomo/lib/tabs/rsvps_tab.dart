import 'package:flutter/material.dart';
import '../data/event.dart';
import '../items/event_item.dart';

class RSVPsTab extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEventTapped;
  final Function(Event, bool) onRSVP;

  const RSVPsTab({super.key, required this.events, required this.onEventTapped, required this.onRSVP});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No RSVPs yet',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return Material(
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventItem(
            event: event,
            onRSVP: (rsvpd) => onRSVP(event, rsvpd),
            onPressed: () => onEventTapped(event),
          );
        },
      ),
    );
  }
}