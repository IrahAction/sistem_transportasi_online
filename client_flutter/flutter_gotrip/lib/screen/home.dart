import 'package:flutter/material.dart';
import '../services/api.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoTrip Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Api.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Berhasil logout")),
              );
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Selamat datang di GoTrip!'),
      ),
    );
  }
}
