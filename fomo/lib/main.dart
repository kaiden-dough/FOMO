import 'package:flutter/material.dart';
import 'widgets/app_bar.dart';
import 'widgets/nav_bar.dart';
import 'tabs/events_tab.dart';
import 'tabs/rsvps_tab.dart';
import 'tabs/post_tab.dart';
import 'tabs/friends_tab.dart';
import 'tabs/account_tab.dart';

class MyScaffold extends StatefulWidget {
  const MyScaffold({super.key});

@override
  State<MyScaffold> createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    EventsTab(),
    RSVPsTab(),
    PostTab(),
    FriendsTab(),
    AccountTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          FomoAppBar(),
          Expanded(child: _screens[_selectedIndex]),
          NavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: (index) => setState(() => _selectedIndex = index),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(
    const MaterialApp(
      title: 'My app',
      home: SafeArea(child: MyScaffold()),
    ),
  );
}