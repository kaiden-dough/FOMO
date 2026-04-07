import 'package:flutter/material.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text(
          'Account',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}