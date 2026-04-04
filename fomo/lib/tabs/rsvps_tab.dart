import 'package:flutter/material.dart';

class RSVPsTab extends StatelessWidget {
  const RSVPsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'RSVPs',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}