import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:remote_protocol/remote_protocol.dart';

class WebSocketServer {
  HttpServer? _server;
  final int port;
  final List<WebSocketChannel> _clients = [];
  final Function(Map<String, dynamic>) onMessageReceived;
  final Function(WebSocketChannel) onClientConnected;
  final Function(WebSocketChannel) onClientDisconnected;

  WebSocketServer({
    required this.port,
    required this.onMessageReceived,
    required this.onClientConnected,
    required this.onClientDisconnected,
  });

  Future<void> start() async {
    final handler = webSocketHandler((WebSocketChannel webSocket) {
      print('Client connected');
      _clients.add(webSocket);
      onClientConnected(webSocket);

      webSocket.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            print('Received message: ${data['type']}');
            onMessageReceived(data);
          } catch (e) {
            print('Error parsing message: $e');
          }
        },
        onDone: () {
          print('Client disconnected');
          _clients.remove(webSocket);
          onClientDisconnected(webSocket);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _clients.remove(webSocket);
          onClientDisconnected(webSocket);
        },
      );
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    print('WebSocket server listening on ${_server!.address.address}:${_server!.port}');
  }

  void broadcast(String message) {
    for (final client in _clients) {
      try {
        client.sink.add(message);
      } catch (e) {
        print('Error broadcasting to client: $e');
      }
    }
  }

  void sendToClient(WebSocketChannel client, String message) {
    try {
      client.sink.add(message);
    } catch (e) {
      print('Error sending to client: $e');
    }
  }

  Future<void> stop() async {
    for (final client in _clients) {
      await client.sink.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    print('WebSocket server stopped');
  }

  int get clientCount => _clients.length;
  bool get isRunning => _server != null;
}
