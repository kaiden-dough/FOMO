import 'package:flutter/material.dart';

class PostTab extends StatelessWidget {
  const PostTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Post',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}