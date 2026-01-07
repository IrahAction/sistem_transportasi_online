import 'package:flutter/material.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                'Pilih Peran Anda',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),

              buildRoleButton(context, "Customer", "user"),
              buildRoleButton(context, "Driver", "driver"),
              buildRoleButton(context, "Merchant", "merchant"),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRoleButton(BuildContext context, String title, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(240, 50),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/login', arguments: {'role': role});
        },
        child: Text(title, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
