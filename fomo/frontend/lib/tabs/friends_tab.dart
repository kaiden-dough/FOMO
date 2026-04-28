import 'package:flutter/material.dart';
import '../data/user.dart';
import '../data/event.dart';
import '../pages/find_friends_page.dart';
import '../items/event_item.dart';

class FriendsTab extends StatefulWidget {
  final List<User> following;
  final List<User> followers;
  final List<Event> feedEvents;
  final List<User> potentialFriends;
  final Future<void> Function(User) onFollow;
  final Future<void> Function(User) onUnfollow;
  final Function(Event) onEventTapped;
  final Function(Event, bool) onRSVP;

  const FriendsTab({
    super.key,
    required this.following,
    required this.followers,
    required this.feedEvents,
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
  bool _showListView = true;

  @override
  Widget build(BuildContext context) {
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
          _buildViewSwitcher(),
          Expanded(
            child: _showListView
                ? widget.feedEvents.isEmpty
                    ? const Center(
                        child: Text(
                          'No feed events yet',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.feedEvents.length,
                        itemBuilder: (context, index) {
                          final event = widget.feedEvents[index];
                          return EventItem(
                            event: event,
                            onRSVP: (rsvpd) => widget.onRSVP(event, rsvpd),
                            onPressed: () => widget.onEventTapped(event),
                          );
                        },
                      )
                : const Center(
                    child: Text(
                      'Map view is not available yet',
                      style: TextStyle(color: Colors.white),
                    ),
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
