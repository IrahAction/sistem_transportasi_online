import 'package:flutter/material.dart';
import '../../services/api.dart';

class MerchantHome extends StatefulWidget {
  const MerchantHome({super.key});

  @override
  State<MerchantHome> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  List<dynamic> pendingOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingOrders();
  }

  Future<void> fetchPendingOrders() async {
    setState(() => isLoading = true);
    try {
      final token = Api.getToken();
      final res = await Api.getFoodOrders(token!);

      if (res["success"] == true) {
        setState(() => pendingOrders = res["data"]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Gagal memuat pesanan")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final token = Api.getToken();
    final res = await Api.updateOrderStatus(
      token!,
      orderId,
      null,
      status,
    );

    if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pesanan berhasil di${status == 'accepted' ? 'terima' : 'tolak'}")),
      );
      fetchPendingOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Gagal memperbarui pesanan")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GoTrip - Merchant Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchPendingOrders,
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
          : pendingOrders.isEmpty
              ? const Center(child: Text("Tidak ada pesanan makanan saat ini 🍜"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingOrders.length,
                  itemBuilder: (context, index) {
                    final order = pendingOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text("Order #${order['order_id']}"),
                        subtitle: Text(
                            "Dari: ${order['origin']}\nKe: ${order['destination']}\nTotal: Rp${order['price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () =>
                                  updateOrderStatus(order['order_id'], 'accepted'),
                              tooltip: "Terima Pesanan",
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  updateOrderStatus(order['order_id'], 'rejected'),
                              tooltip: "Tolak Pesanan",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
