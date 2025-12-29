import 'package:flutter/material.dart';

class RiderHome extends StatelessWidget {
  const RiderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rider Home")),
      body: const Center(
        child: Text(
          "Pickup & Drop Screen (Google Maps next)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
