import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/event.dart';
import '../items/event_item.dart';

class EventDetailsPage extends StatelessWidget {
  final Event event;
  final Function(bool) onRSVP;
  final VoidCallback onBack;

  const EventDetailsPage({
    super.key,
    required this.event,
    required this.onRSVP,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(DateFormat('MMM d • h:mm a').format(event.date), style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(event.location, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text('${event.attending} attending', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Text(event.description, style: TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                RSVPButton(
                  initialRsvpd: event.isRsvpd,
                  onRSVP: onRSVP,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
