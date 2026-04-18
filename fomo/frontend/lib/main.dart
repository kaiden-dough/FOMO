import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'widgets/app_bar.dart';
import 'widgets/nav_bar.dart';
import 'tabs/events_tab.dart';
import 'tabs/rsvps_tab.dart';
import 'tabs/post_tab.dart';
import 'tabs/friends_tab.dart';
import 'tabs/account_tab.dart';
import 'data/event.dart';import 'data/user.dart';import 'data/user.dart';
import 'pages/event_details_page.dart';

final uuid = Uuid();

class MyScaffold extends StatefulWidget {
  const MyScaffold({super.key});

@override
  State<MyScaffold> createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  int _selectedIndex = 0;
  Event? _selectedEvent;

  // Mock users
  final List<User> _mockUsers = [
    User(id: 'u1', name: 'Alice', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u2', name: 'Bob', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u3', name: 'Charlie', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u4', name: 'Diana', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u5', name: 'Eve', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u6', name: 'Frank', avatarUrl: 'https://via.placeholder.com/50'),
  ];

  // Friends data
  List<User> following = [
    User(id: 'u1', name: 'Alice', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u2', name: 'Bob', avatarUrl: 'https://via.placeholder.com/50'),
  ];

  List<User> followers = [
    User(id: 'u3', name: 'Charlie', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u4', name: 'Diana', avatarUrl: 'https://via.placeholder.com/50'),
  ];

  List<User> potentialFriends = [
    User(id: 'u7', name: 'Grace', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u8', name: 'Henry', avatarUrl: 'https://via.placeholder.com/50'),
    User(id: 'u9', name: 'Ivy', avatarUrl: 'https://via.placeholder.com/50'),
  ];

  final List<Event> _events = [   // get events from backend
    Event(
      id: uuid.v4(),
      title: "Concert in the Park",
      date: DateTime(2026, 4, 5, 20, 30),
      location: "Central Park",
      attending: 42,
      description: "Join us for a night of music and fun in the park!",
      poster: User(id: 'u1', name: 'Alice', avatarUrl: 'https://via.placeholder.com/50'),
      // imageUrl: "https://example.com/concert.jpg",
    ),
    Event(
      id: uuid.v4(),
      title: "Food Truck Festival",
      date: DateTime(2026, 5, 10, 12, 0),
      location: "Downtown",
      attending: 85,
      description: "Taste delicious food from the best food trucks in town!",
      poster: User(id: 'u2', name: 'Bob', avatarUrl: 'https://via.placeholder.com/50'),
      // imageUrl: "https://example.com/food_truck.jpg",
    ),
    Event(
      id: uuid.v4(),
      title: "Art Gallery Opening",
      date: DateTime(2026, 6, 15, 18, 0),
      location: "City Art Gallery",
      attending: 30,
      description: "Experience the latest art from local artists at our gallery opening.",
      poster: User(id: 'u3', name: 'Charlie', avatarUrl: 'https://via.placeholder.com/50'),
      // imageUrl: "https://example.com/art_gallery.jpg",
    ),
    Event(
      id: uuid.v4(),
      title: "Outdoor Movie Night",
      date: DateTime(2026, 7, 20, 20, 0),
      location: "Riverside Park",
      attending: 60,
      description: "Bring your blankets and enjoy a movie under the stars at our outdoor movie night!",
      poster: User(id: 'u4', name: 'Diana', avatarUrl: 'https://via.placeholder.com/50'),
      // imageUrl: "https://example.com/movie_night.jpg",
    ),
    Event(
      id: uuid.v4(),
      title: "Open Mic Night",
      date: DateTime(2026, 5, 10, 12, 0),
      location: "Downtown",
      attending: 85,
      description: "Show off your talents at our open mic night! Sing, perform comedy, or share your poetry with the community.",
      poster: User(id: 'u5', name: 'Eve', avatarUrl: 'https://via.placeholder.com/50'),
      // imageUrl: "https://example.com/open_mic.jpg",
    ),
    Event(
      id: uuid.v4(),
      title: "Tech Meetup",
      date: DateTime(2026, 8, 25, 18, 0),
      location: "Tech Hub",
      attending: 50,
      description: "Connect with fellow tech enthusiasts at our monthly tech meetup. Share ideas, network, and learn about the latest trends in technology.",
      poster: User(id: 'u6', name: 'Frank', avatarUrl: 'https://via.placeholder.com/50'),
      // imageUrl: "https://example.com/tech_meetup.jpg",
    ),
  ];

  void _onEventTapped(Event event) {
    setState(() => _selectedEvent = event);
  }

  void _onRSVP(Event event, bool rsvpd) {
    setState(() {
      event.isRsvpd = rsvpd;
      event.attending += rsvpd ? 1 : -1;
    });
  }

  void _onEventPosted(Event event) {
    setState(() => _events.add(event));
  }

  void _onFollow(User user) {
    setState(() {
      if (!following.contains(user)) {
        following.add(user);
      }
    });
  }

  void _onUnfollow(User user) {
    setState(() {
      following.remove(user);
    });
  }

  Widget _buildBody() {
    if (_selectedEvent != null) {
      return EventDetailsPage(
        event: _selectedEvent!,
        onRSVP: (rsvpd) => _onRSVP(_selectedEvent!, rsvpd),
        onBack: () => setState(() => _selectedEvent = null),
      );
    }

    switch (_selectedIndex) {
      case 0: return EventsTab(
        events: _events,
        onEventTapped: _onEventTapped,
        onRSVP: _onRSVP,
      );
      case 1: return RSVPsTab(
        events: _events.where((element) => element.isRsvpd).toList(),
        onEventTapped: _onEventTapped,
        onRSVP: _onRSVP,
      );
      case 2: return PostTab(onEventPosted: _onEventPosted);
      case 3: return FriendsTab(
        following: following,
        followers: followers,
        allEvents: _events,
        potentialFriends: potentialFriends,
        onFollow: _onFollow,
        onUnfollow: _onUnfollow,
        onEventTapped: _onEventTapped,
        onRSVP: _onRSVP,
      );
      case 4: return AccountTab();
      default: return EventsTab(
        events: _events,
        onEventTapped: _onEventTapped,
        onRSVP: _onRSVP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          FomoAppBar(),
          Expanded(child: _buildBody()),
          NavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: (index) => setState(() {
              _selectedIndex = index;
              _selectedEvent = null;
            }),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(),
      ),
      title: 'My app',
      home: SafeArea(child: MyScaffold()),
    ),
  );
}