import 'package:flutter/material.dart';
import '../items/nav_item.dart';

class NavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const NavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: Colors.black),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NavItem(icon: Icons.location_on, label: 'Events', isSelected: selectedIndex == 0, onPressed: () => onItemTapped(0)),
          NavItem(icon: Icons.event_available, label: 'RSVPs', isSelected: selectedIndex == 1, onPressed: () => onItemTapped(1)),
          NavItem(icon: Icons.add_box, label: 'Post', isSelected: selectedIndex == 2, onPressed: () => onItemTapped(2)),
          NavItem(icon: Icons.people, label: 'Friends', isSelected: selectedIndex == 3, onPressed: () => onItemTapped(3)),
          NavItem(icon: Icons.account_circle, label: 'Account', isSelected: selectedIndex == 4, onPressed: () => onItemTapped(4)),
        ],
      ),
    );
  }
}