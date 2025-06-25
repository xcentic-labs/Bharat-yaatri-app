import 'package:flutter/material.dart';

class AddPlusButtonScreen extends StatelessWidget {
  const AddPlusButtonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Add Plus Button Screen (Dummy Data)',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}