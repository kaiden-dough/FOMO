import 'package:flutter/material.dart';
import '../data/event.dart';
import '../items/event_item.dart';

class EventsTab extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEventTapped;
  final Function(Event, bool) onRSVP;

  const EventsTab({super.key, required this.events, required this.onEventTapped, required this.onRSVP});

  @override
  Widget build(BuildContext context) {
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