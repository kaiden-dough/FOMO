import 'package:flutter/material.dart';
import '../data/user.dart';
import '../data/event.dart';
import '../pages/find_friends_page.dart';
import '../items/event_item.dart';

class FriendsTab extends StatefulWidget {
  final List<User> following;
  final List<User> followers;
  final List<Event> allEvents;
  final List<User> potentialFriends;
  final Function(User) onFollow;
  final Function(User) onUnfollow;
  final Function(Event) onEventTapped;
  final Function(Event, bool) onRSVP;

  const FriendsTab({
    super.key,
    required this.following,
    required this.followers,
    required this.allEvents,
    required this.potentialFriends,
    required this.onFollow,
    required this.onUnfollow,
    required this.onEventTapped,
    required this.onRSVP,
  });

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {

  @override
  Widget build(BuildContext context) {
    // Filter events from following
    final feedEvents = widget.allEvents.where((event) =>
      widget.following.any((user) => user.id == event.poster.id)
    ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top row with counts and plus button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      '${widget.following.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Following',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${widget.followers.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Followers',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FindFriendsPage(
                          potentialFriends: widget.potentialFriends,
                          onFollow: widget.onFollow,
                          onUnfollow: widget.onUnfollow,
                          following: widget.following,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Feed of events
          Expanded(
            child: ListView.builder(
              itemCount: feedEvents.length,
              itemBuilder: (context, index) {
                final event = feedEvents[index];
                return EventItem(
                  event: event,
                  onRSVP: (rsvpd) => widget.onRSVP(event, rsvpd),
                  onPressed: () => widget.onEventTapped(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}