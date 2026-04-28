import 'package:flutter/material.dart';
import '../data/event.dart';
import '../items/event_item.dart';
import '../widgets/events_map.dart';

class RSVPsTab extends StatefulWidget {
  final List<Event> events;
  final Function(Event) onEventTapped;
  final Function(Event, bool) onRSVP;

  const RSVPsTab({super.key, required this.events, required this.onEventTapped, 
required this.onRSVP});

  @override
  State<RSVPsTab> createState() => _RSVPsTabState();
}

class _RSVPsTabState extends State<RSVPsTab> {
  bool _showListView = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Column(
        children: [
          _buildViewSwitcher(),
          Expanded(
            child: _showListView
                ? widget.events.isEmpty
                    ? const Center(
                        child: Text(
                          'No RSVPs yet',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.events.length,
                        itemBuilder: (context, index) {
                          final event = widget.events[index];
                          return EventItem(
                            event: event,
                            onRSVP: (rsvpd) => widget.onRSVP(event, rsvpd),
                            onPressed: () => widget.onEventTapped(event),
                          );
                        },
                      )
                : EventsMap(
                    events: widget.events,
                    onEventTapped: widget.onEventTapped,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ToggleButtons(
        isSelected: [_showListView, !_showListView],
        onPressed: (index) {
          setState(() {
            _showListView = index == 0;
          });
        },
        borderRadius: BorderRadius.circular(8.0),
        borderColor: Colors.white24,
        selectedBorderColor: Colors.white,
        fillColor: Colors.white12,
        color: Colors.white70,
        selectedColor: Colors.white,
        constraints: const BoxConstraints(minWidth: 100, minHeight: 40),
        children: const [
          Text('List View'),
          Text('Map View'),
        ],
      ),
    );
  }
}
