import 'package:flutter/material.dart';

class FomoAppBar extends StatelessWidget {
  const FomoAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Image.asset('assets/FOMO_logo.png'),
            ),
          ),
        ],
      ),
    );
  }
}