import 'package:flutter/material.dart';

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSelected;

  const NavItem({required this.icon, required this.label, required this.onPressed, required this.isSelected, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


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