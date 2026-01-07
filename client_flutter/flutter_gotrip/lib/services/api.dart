import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Api {
  static String baseUrl = dotenv.env['API_URL'] ?? "http://localhost:5000";

  // === LOGIN ===
  static Future<Map<String, dynamic>?> login(
      String email, String password, String role) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": role,
        }),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data["success"] == true) {
        // Simpan token dan role di browser
        html.window.localStorage["token"] = data["token"];
        html.window.localStorage["role"] = data["role"];
      }

      return data;
    } catch (e) {
      return {
        "success": false,
        "message": "Error connecting to server: $e",
      };
    }
  }

  // === REGISTER ===
  static Future<Map<String, dynamic>?> register(
      String name, String email, String pass, String role) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": pass,
          "role": role,
        }),
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        "success": false,
        "message": "Error connecting to server: $e",
      };
    }
  }

  // === CREATE ORDER ===
  static Future<Map<String, dynamic>> createOrder({
    required int userId,
    required String type,
    String? pickup,
    String? dropoff,
    int? merchantId,
    double? total,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final token = html.window.localStorage["token"];

      final res = await http.post(
        Uri.parse("$baseUrl/api/order/create"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "type": type,
          "pickup": pickup,
          "dropoff": dropoff,
          "merchant_id": merchantId,
          "total": total,
          "items": items,
        }),
      );

      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
  //cari order terdekat
  static Future<Map<String, dynamic>> getNearbyOrders(double lat, double lng) async {
  try {
    final token = html.window.localStorage["token"];
    final res = await http.get(
      Uri.parse("$baseUrl/api/order/nearby?lat=$lat&lng=$lng"),
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(res.body);
  } catch (e) {
    return {"success": false, "message": "Error: $e"};
  }
}

  //DRIVER: Ambil order pending 
  static Future<Map<String, dynamic>> getPendingOrders(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/order/pending"),
        headers: {"Authorization": "Bearer $token"},
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
  // DRIVER: Ambil order yang diterima
  static Future<Map<String, dynamic>> getAcceptedOrders(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/order/accepted"),
        headers: {"Authorization": "Bearer $token"},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  // DRIVER: Selesaikan order
  static Future<Map<String, dynamic>> completeOrder(String token, int id) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/order/complete/$id"),
        headers: {"Authorization": "Bearer $token"},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
  //DRIVER: Update status order
  static Future<Map<String, dynamic>> updateOrderStatus(
      String token, int orderId, String? driverId, String status) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/order/update/$orderId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "driver_id": driverId,
          "status": status,
        }),
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
  //MERCHANT: Ambil order bertipe food
  static Future<Map<String, dynamic>> getFoodOrders(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/order/food"),
        headers: {"Authorization": "Bearer $token"},
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  //UTIL
  static bool isLoggedIn() {
    return html.window.localStorage.containsKey("token");
  }

  static String? getRole() {
    return html.window.localStorage["role"];
  }

  static String? getToken() {
    return html.window.localStorage["token"];
  }

  static void logout() {
    html.window.localStorage.remove("token");
    html.window.localStorage.remove("role");
  }
}
