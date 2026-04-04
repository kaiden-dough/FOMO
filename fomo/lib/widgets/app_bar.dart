import 'package:flutter/material.dart';

class FomoAppBar extends StatelessWidget {
  const FomoAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: const Color.fromARGB(255, 0, 0, 0)),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'FOMO',
                style:
                Theme.of(context).primaryTextTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}