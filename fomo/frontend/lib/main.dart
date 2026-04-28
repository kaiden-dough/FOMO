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
  bool _isAuthenticated = false;
  String? _error;
  bool _eventsShowListView = true;
  bool _rsvpsShowListView = true;
  final ScrollController _eventsScrollController = ScrollController();
  final ScrollController _rsvpsScrollController = ScrollController();

  List<Event> _events = [];
  List<Event> _myRsvps = [];
  List<User> _following = [];
  List<User> _followers = [];
  List<User> _potentialFriends = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _eventsScrollController.dispose();
    _rsvpsScrollController.dispose();
    super.dispose();
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
          _isAuthenticated = false;
          _events = [];
          _myRsvps = [];
          _following = [];
          _followers = [];
          _potentialFriends = [];
        });
        return;
      }

      final events = await _backend.fetchEvents();
      final myRsvps = await _backend.fetchMyRsvps();
      final friends = await _backend.fetchFriends();
      if (!mounted) return;
      setState(() {
        _isAuthenticated = true;
        _events = events;
        _myRsvps = myRsvps;
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
    if (!_isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to RSVP.')),
      );
      setState(() => _selectedIndex = 4);
      return;
    }
    final previousRsvp = event.isRsvpd;
    final previousAttending = event.attending;
    setState(() {
      _applyEventLocalUpdate(event.id, rsvpd, previousAttending + (rsvpd ? 1 : -1));
    });

    try {
      if (rsvpd) {
        await _backend.rsvp(event.id);
      } else {
        await _backend.unrsvp(event.id);
      }
      await _refreshRsvps();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applyEventLocalUpdate(event.id, previousRsvp, previousAttending);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update RSVP.')),
      );
    }
  }

  void _promptLoginForRsvp() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login required to RSVP.')),
    );
    setState(() => _selectedIndex = 4);
  }

  Future<void> _refreshRsvps() async {
    final myRsvps = await _backend.fetchMyRsvps();
    if (!mounted) return;
    setState(() {
      _myRsvps = myRsvps;
      final rsvpIds = _myRsvps.map((e) => e.id).toSet();
      for (final event in _events) {
        event.isRsvpd = rsvpIds.contains(event.id);
      }
    });
  }

  void _applyEventLocalUpdate(String eventId, bool rsvpd, int attending) {
    final safeAttending = attending.clamp(0, 1 << 30);
    for (final e in _events) {
      if (e.id == eventId) {
        e.isRsvpd = rsvpd;
        e.attending = safeAttending;
      }
    }
    for (final e in _myRsvps) {
      if (e.id == eventId) {
        e.isRsvpd = rsvpd;
        e.attending = safeAttending;
      }
    }
    if (_selectedEvent?.id == eventId) {
      _selectedEvent!.isRsvpd = rsvpd;
      _selectedEvent!.attending = safeAttending;
    }
  }

  Future<void> _onEventPosted(Event event) async {
    if (!_isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to post events.')),
      );
      setState(() => _selectedIndex = 4);
      return;
    }
    try {
      await _backend.postEvent(
        id: event.id,
        title: event.title,
        date: event.date,
        location: event.location,
        description: event.description,
        latitude: event.latitude,
        longitude: event.longitude,
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
    if (!_isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to follow users.')),
      );
      setState(() => _selectedIndex = 4);
      return;
    }
    await _backend.follow(user.id);
    await _refreshData();
  }

  Future<void> _onUnfollow(User user) async {
    if (!_isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to manage follows.')),
      );
      setState(() => _selectedIndex = 4);
      return;
    }
    await _backend.unfollow(user.id);
    await _refreshData();
  }

  Widget _buildBody() {
    if (!_isAuthenticated && _selectedIndex != 0 && _selectedIndex != 4) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please login to use this section.',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 4),
              child: const Text('Go to Account'),
            ),
          ],
        ),
      );
    }

    if (_selectedEvent != null) {
      return EventDetailsPage(
        event: _selectedEvent!,
        onRSVP: (rsvpd) => _onRSVP(_selectedEvent!, rsvpd),
        onBack: () => setState(() => _selectedEvent = null),
        canRSVP: _isAuthenticated,
        onRSVPDisabledTap: _promptLoginForRsvp,
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
          canRSVP: _isAuthenticated,
          onRSVPDisabledTap: _promptLoginForRsvp,
          showListView: _eventsShowListView,
          onViewModeChanged: (showList) => setState(() => _eventsShowListView = showList),
          listScrollController: _eventsScrollController,
        );
      case 1:
        return RSVPsTab(
          events: _myRsvps,
          onEventTapped: (event) => setState(() => _selectedEvent = event),
          onRSVP: (event, rsvpd) => _onRSVP(event, rsvpd),
          showListView: _rsvpsShowListView,
          onViewModeChanged: (showList) => setState(() => _rsvpsShowListView = showList),
          listScrollController: _rsvpsScrollController,
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
    return Scaffold(
      body: Column(
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