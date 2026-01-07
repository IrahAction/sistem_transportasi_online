import 'dart:html' as html;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final MapController mapController = MapController();
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  String selectedType = 'ride';
  bool isSelectingPickup = true;
  bool isLoading = false;

  double distanceKm = 0.0;
  double totalUserBayar = 0.0;
  double komisiDriver = 0.0;

  // =====================
  // HITUNG JARAK (Haversine)
  // =====================
  double calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // km
    var dLat = (lat2 - lat1) * pi / 180;
    var dLon = (lon2 - lon1) * pi / 180;

    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // =====================
  // HITUNG TARIF & KOMISI
  // =====================
  void updatePrice() {
    if (pickupLocation == null || dropoffLocation == null) return;

    distanceKm = calculateDistance(
      pickupLocation!.latitude,
      pickupLocation!.longitude,
      dropoffLocation!.latitude,
      dropoffLocation!.longitude,
    );

    double biayaPerKm = 1850;
    double biayaLayanan = 1000;

    double hargaDasar = distanceKm * biayaPerKm;
    totalUserBayar = hargaDasar + biayaLayanan;
    komisiDriver = hargaDasar * 0.70;

    setState(() {});
  }

  // =====================
  // KIRIM ORDER
  // =====================
  Future<void> _createOrder() async {
    if (pickupLocation == null || dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tentukan titik jemput & tujuan di peta")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = int.tryParse(html.window.localStorage["user_id"] ?? '0') ?? 0;

      final res = await Api.createOrder(
        userId: userId,
        type: selectedType,
        pickup:
            "${pickupLocation!.latitude},${pickupLocation!.longitude}",
        dropoff:
            "${dropoffLocation!.latitude},${dropoffLocation!.longitude}",
        total: totalUserBayar,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Order berhasil dibuat")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat order: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoTrip - User Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Api.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ============ MAP ============
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(-7.2575, 112.7521),
                initialZoom: 13,
                onTap: (tapPosition, point) {
                  setState(() {
                    if (isSelectingPickup) {
                      pickupLocation = point;
                      isSelectingPickup = false;
                    } else {
                      dropoffLocation = point;
                      isSelectingPickup = true;
                    }
                  });

                  updatePrice(); // hitung tarif
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.gotrip',
                ),
                if (pickupLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pickupLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on,
                            color: Colors.green, size: 35),
                      ),
                    ],
                  ),
                if (dropoffLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: dropoffLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.flag,
                            color: Colors.red, size: 35),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ============ INFO TARIF ============
          if (pickupLocation != null && dropoffLocation != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text("Estimasi jarak: ${distanceKm.toStringAsFixed(2)} km"),
                  Text("Total biaya user: Rp ${totalUserBayar.toInt()}"),
                  Text("Komisi Driver: Rp ${komisiDriver.toInt()}"),
                  const SizedBox(height: 10),
                ],
              ),
            ),

          // ============ FORM ORDER ============
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: "Jenis Layanan"),
                  items: const [
                    DropdownMenuItem(value: 'ride', child: Text('Ride')),
                    DropdownMenuItem(value: 'food', child: Text('Food Delivery')),
                    DropdownMenuItem(value: 'package', child: Text('Package Delivery')),
                  ],
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                const SizedBox(height: 15),

                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _createOrder,
                        icon: const Icon(Icons.send),
                        label: const Text("Kirim Order"),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
