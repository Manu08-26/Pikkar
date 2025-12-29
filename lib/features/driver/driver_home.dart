import 'package:flutter/material.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Home")),
      body: const Center(
        child: Text(
          "Waiting for ride requests",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
