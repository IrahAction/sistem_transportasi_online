import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:html' as html;

class SocketService {
  static IO.Socket? socket;

  static void connect() {
    final token = html.window.localStorage["token"];
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      'http://localhost:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'token': token}) // or auth via auth:{token}
          .build(),
    );
    socket!.onConnect((_) {
      print('socket connected: ${socket!.id}');
    });

    socket!.onDisconnect((_) {
      print('socket disconnected');
    });

    socket!.on('order:driver_location', (data) {
      // handle incoming driver location updates 
      print('driver location update: $data');
    });

    socket!.on('order:completed', (data) {
      print('order completed: $data');
      // optionally show notification and refresh UI
    });
  }

  static void joinOrderRoom(int orderId) {
    socket?.emit('order:join', {'order_id': orderId});
  }

  static void sendDriverLocation(int? orderId, double lat, double lng) {
    socket?.emit('driver:location', {'order_id': orderId, 'lat': lat, 'lng': lng});
  }
}
