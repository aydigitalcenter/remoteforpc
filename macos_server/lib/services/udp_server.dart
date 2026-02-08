import 'dart:io';
import 'dart:convert';
import 'package:remote_protocol/remote_protocol.dart';

class UdpServer {
  RawDatagramSocket? _socket;
  final int port;
  final Function(MouseMoveMessage) onMouseMove;

  UdpServer({
    required this.port,
    required this.onMouseMove,
  });

  Future<void> start() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    print('UDP server listening on ${_socket!.address.address}:${_socket!.port}');

    _socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) {
          try {
            final message = utf8.decode(datagram.data);
            final data = jsonDecode(message) as Map<String, dynamic>;
            
            if (data['type'] == 'mouse_move') {
              final mouseMove = MouseMoveMessage.fromJson(data);
              onMouseMove(mouseMove);
            }
          } catch (e) {
            print('Error parsing UDP message: $e');
          }
        }
      }
    });
  }

  Future<void> stop() async {
    _socket?.close();
    _socket = null;
    print('UDP server stopped');
  }

  bool get isRunning => _socket != null;
}
