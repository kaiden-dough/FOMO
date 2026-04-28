import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'data/event.dart';
import 'data/user.dart';
import 'pages/event_details_page.dart';
import 'services/auth_service.dart';
import 'services/backend_service.dart';
import 'tabs/account_tab.dart';
import 'tabs/events_tab.dart';
import 'tabs/friends_tab.dart';
import 'tabs/post_tab.dart';
import 'tabs/rsvps_tab.dart';
import 'widgets/app_bar.dart';
import 'widgets/nav_bar.dart';

final uuid = Uuid();

class MyScaffold extends StatefulWidget {
  const MyScaffold({super.key});

  @override
  State<MyScaffold> createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  final BackendService _backend = BackendService();
  final AuthService _auth = AuthService();

  int _selectedIndex = 0;
  Event? _selectedEvent;
  bool _loading = true;
  String? _error;

  List<Event> _events = [];
  List<User> _following = [];
  List<User> _followers = [];
  List<User> _potentialFriends = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final account = await _auth.getCurrentAccount();
      if (account == null) {
        if (!mounted) return;
        setState(() {
          _events = [];
          _following = [];
          _followers = [];
          _potentialFriends = [];
        });
        return;
      }

      final events = await _backend.fetchEvents();
      final friends = await _backend.fetchFriends();
      if (!mounted) return;
      setState(() {
        _events = events;
        _following = friends.following;
        _followers = friends.followers;
        _potentialFriends = friends.suggested;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load backend data.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onRSVP(Event event, bool rsvpd) async {
    final previousRsvp = event.isRsvpd;
    final previousAttending = event.attending;
    setState(() {
      event.isRsvpd = rsvpd;
      event.attending = (event.attending + (rsvpd ? 1 : -1)).clamp(0, 1 << 30);
    });

    try {
      if (rsvpd) {
        await _backend.rsvp(event.id);
      } else {
        await _backend.unrsvp(event.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        event.isRsvpd = previousRsvp;
        event.attending = previousAttending;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update RSVP.')),
      );
    }
  }

  Future<void> _onEventPosted(Event event) async {
    try {
      await _backend.postEvent(
        id: event.id,
        title: event.title,
        date: event.date,
        location: event.location,
        description: event.description,
      );
      await _refreshData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event posted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post event: $e')),
      );
    }
  }

  Future<void> _onFollow(User user) async {
    await _backend.follow(user.id);
    await _refreshData();
  }

  Future<void> _onUnfollow(User user) async {
    await _backend.unfollow(user.id);
    await _refreshData();
  }

  Widget _buildBody() {
    if (_selectedEvent != null) {
      return EventDetailsPage(
        event: _selectedEvent!,
        onRSVP: (rsvpd) => _onRSVP(_selectedEvent!, rsvpd),
        onBack: () => setState(() => _selectedEvent = null),
      );
    }

    if (_loading && _selectedIndex != 4) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _selectedIndex != 4) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _refreshData, child: const Text('Retry')),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return EventsTab(
          events: _events,
          onEventTapped: (event) => setState(() => _selectedEvent = event),
          onRSVP: (event, rsvpd) => _onRSVP(event, rsvpd),
        );
      case 1:
        return RSVPsTab(
          events: _events.where((element) => element.isRsvpd).toList(),
          onEventTapped: (event) => setState(() => _selectedEvent = event),
          onRSVP: (event, rsvpd) => _onRSVP(event, rsvpd),
        );
      case 2:
        return PostTab(
          onEventPosted: _onEventPosted,
        );
      case 3:
        final followedIds = _following.map((u) => u.id).toSet();
        final feedEvents = _events
            .where((event) => followedIds.contains(event.poster.id))
            .toList();
        return FriendsTab(
          following: _following,
          followers: _followers,
          feedEvents: feedEvents,
          potentialFriends: _potentialFriends,
          onFollow: _onFollow,
          onUnfollow: _onUnfollow,
          onEventTapped: (event) => setState(() => _selectedEvent = event),
          onRSVP: (event, rsvpd) => _onRSVP(event, rsvpd),
        );
      case 4:
        return AccountTab(onAuthChanged: _refreshData);
      default:
        return const SizedBox.shrink();
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
        colorScheme: const ColorScheme.dark(),
      ),
      title: 'FOMO',
      home: const SafeArea(child: MyScaffold()),
    ),
  );
}