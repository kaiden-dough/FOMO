import 'package:flutter/material.dart';
import '../data/event.dart';
import '../items/event_item.dart';
import '../widgets/events_map.dart';

class RSVPsTab extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEventTapped;
  final Function(Event, bool) onRSVP;
  final bool? showListView;
  final ValueChanged<bool>? onViewModeChanged;
  final ScrollController? listScrollController;

  const RSVPsTab({super.key, required this.events, required this.onEventTapped, 
required this.onRSVP, this.showListView, this.onViewModeChanged, this.listScrollController});

  @override
  Widget build(BuildContext context) {
    final isListView = showListView ?? true;
    return Material(
      color: Colors.black,
      child: Column(
        children: [
          _buildViewSwitcher(isListView),
          Expanded(
            child: isListView
                ? events.isEmpty
                    ? const Center(
                        child: Text(
                          'No RSVPs yet',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        controller: listScrollController,
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return EventItem(
                            event: event,
                            onRSVP: (rsvpd) => onRSVP(event, rsvpd),
                            onPressed: () => onEventTapped(event),
                          );
                        },
                      )
                : EventsMap(
                    events: events,
                    onEventTapped: onEventTapped,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher(bool isListView) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ToggleButtons(
        isSelected: [isListView, !isListView],
        onPressed: (index) {
          onViewModeChanged?.call(index == 0);
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
