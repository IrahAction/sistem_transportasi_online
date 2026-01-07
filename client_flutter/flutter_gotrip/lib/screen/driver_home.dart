import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../services/socket_services.dart';
import 'package:geolocator/geolocator.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  List<dynamic> acceptedOrders = [];
  List<dynamic> nearbyOrders = [];
  bool isLoading = false;

  // Lokasi driver
  double driverLat = -7.2575;
  double driverLng = 112.7521;

  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    fetchAccepted();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    SocketService.socket?.disconnect();
    super.dispose();
  }

  //Realtime GPS
  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) {
      showError("Location Service dimatikan");
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showError("Lokasi tidak diizinkan");
        return;
      }
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      driverLat = pos.latitude;
      driverLng = pos.longitude;

      int? activeOrderId =
          acceptedOrders.isNotEmpty ? acceptedOrders[0]['order_id'] : null;

      SocketService.sendDriverLocation(activeOrderId, driverLat, driverLng);
    });
  }

  // === Ambil order yang sedang diterima driver ===
  Future<void> fetchAccepted() async {
    setState(() => isLoading = true);
    try {
      final token = Api.getToken();
      final res = await Api.getAcceptedOrders(token!);

      if (res["success"] == true) {
        setState(() => acceptedOrders = res["data"]);
      }
    } catch (e) {
      showError("Error: $e");
    }
    setState(() => isLoading = false);
  }

  // === Ambil 5 order pending terdekat ===
  Future<void> searchNearby() async {
    setState(() => isLoading = true);

    try {
      final res = await Api.getNearbyOrders(driverLat, driverLng);

      if (res["success"] == true) {
        setState(() => nearbyOrders = res["data"]);
      }
    } catch (e) {
      showError("Error: $e");
    }

    setState(() => isLoading = false);
  }

  // === Selesaikan order ===
  Future<void> completeOrder(int id) async {
    final token = Api.getToken();
    final res = await Api.completeOrder(token!, id);

    if (res["success"] == true) {
      showMessage(res["message"]);
      fetchAccepted();
    }
  }

  // === Tarif & Komisi Driver ===
  Map<String, dynamic> calculateFare(double distanceKm) {
    const double biayaPerKm = 1850;
    const double biayaLayanan = 1000;

    double hargaDasar = biayaPerKm * distanceKm;
    double totalUser = hargaDasar + biayaLayanan;
    double komisiDriver = hargaDasar * 0.70;

    return {
      "harga": totalUser,
      "komisi": komisiDriver,
      "dasar": hargaDasar,
    };
  }

  // === UI Helper ===
  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ==========================================
  //                 UI PAGE
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GoTrip - Driver Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: searchNearby,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAccepted,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Api.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : acceptedOrders.isNotEmpty
              ? _buildAcceptedOrders()
              : _buildNearbyOrders(),
    );
  }

  // === Order yang sedang di-ACCEPT driver ===
  Widget _buildAcceptedOrders() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: acceptedOrders.length,
      itemBuilder: (context, index) {
        final order = acceptedOrders[index];
        final distanceKm = (order["distance"] ?? 0.0) * 1.0;
        final tarif = calculateFare(distanceKm);

        return Card(
          child: ListTile(
            title:
                Text("Order #${order['order_id']} (${order['service_type']})"),
            subtitle: Text("""
Dari : ${order['origin']}
Tujuan : ${order['destination']}
Jarak : ${distanceKm.toStringAsFixed(2)} km

💰 Tarif User   : Rp ${tarif["harga"].toInt()}
🚖 Komisi Driver: Rp ${tarif["komisi"].toInt()}
"""),
            trailing: ElevatedButton(
              onPressed: () => completeOrder(order['order_id']),
              child: const Text("Selesaikan"),
            ),
          ),
        );
      },
    );
  }

  // === 5 Order Pending Terdekat ===
  Widget _buildNearbyOrders() {
    if (nearbyOrders.isEmpty) {
      return const Center(child: Text("Tidak ada order terdekat"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: nearbyOrders.length,
      itemBuilder: (context, index) {
        final order = nearbyOrders[index];
        final distanceKm = (order["distance"] ?? 0.0) * 1.0;
        final tarif = calculateFare(distanceKm);

        return Card(
          child: ListTile(
            title:
                Text("Order #${order['order_id']} (${order['service_type']})"),
            subtitle: Text("""
Jarak : ${distanceKm.toStringAsFixed(2)} km
Dari  : ${order['origin']}
Ke    : ${order['destination']}

Tarif User   : Rp ${tarif["harga"].toInt()}
Komisi Driver: Rp ${tarif["komisi"].toInt()}
"""),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Buat endpoint accept order
              },
              child: const Text("Ambil"),
            ),
          ),
        );
      },
    );
  }
}
