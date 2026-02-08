import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remote_protocol/remote_protocol.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class ConnectionService extends ChangeNotifier {
  WebSocketChannel? _wsChannel;
  RawDatagramSocket? _udpSocket;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;
  String? _serverHost;
  int? _serverPort;
  int _udpSequence = 0;

  ConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Connect to server with pairing
  Future<bool> connectWithPairing({
    required String host,
    required int port,
    required String pin,
    required String deviceId,
    required String deviceName,
  }) async {
    _updateStatus(ConnectionStatus.connecting);
    _serverHost = host;
    _serverPort = port;

    try {
      // Connect via WebSocket
      final uri = Uri.parse('ws://$host:$port');
      _wsChannel = WebSocketChannel.connect(uri);

      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      // Send pairing request
      final pairRequest = PairRequestMessage(
        pin: pin,
        deviceId: deviceId,
        deviceName: deviceName,
      );
      _wsChannel!.sink.add(pairRequest.toJsonString());

      // Wait for pairing response
      final completer = Completer<bool>();
      
      _wsChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          if (data['type'] == 'pair_response') {
            final response = PairResponseMessage.fromJson(data);
            if (response.success && response.token != null) {
              // Save token
              _saveToken(deviceId, response.token!);
              completer.complete(true);
            } else {
              _errorMessage = response.errorMessage ?? 'Pairing failed';
              completer.complete(false);
            }
          }
        },
        onError: (error) {
          _errorMessage = error.toString();
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      final success = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _errorMessage = 'Pairing timeout';
          return false;
        },
      );

      if (success) {
        await _setupUdpConnection();
        _updateStatus(ConnectionStatus.connected);
        return true;
      } else {
        await disconnect();
        _updateStatus(ConnectionStatus.error);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  /// Connect with stored token
  Future<bool> connectWithToken({
    required String host,
    required int port,
    required String deviceId,
  }) async {
    _updateStatus(ConnectionStatus.connecting);
    _serverHost = host;
    _serverPort = port;

    try {
      final token = await _getToken(deviceId);
      if (token == null) {
        _errorMessage = 'No stored token found';
        _updateStatus(ConnectionStatus.error);
        return false;
      }

      // Connect via WebSocket
      final uri = Uri.parse('ws://$host:$port');
      _wsChannel = WebSocketChannel.connect(uri);

      await Future.delayed(const Duration(milliseconds: 500));

      // Send authentication
      final authMessage = AuthenticationMessage(
        token: token,
        deviceId: deviceId,
      );
      _wsChannel!.sink.add(authMessage.toJsonString());

      await _setupUdpConnection();
      _updateStatus(ConnectionStatus.connected);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  Future<void> _setupUdpConnection() async {
    if (_serverHost == null) return;

    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      print('UDP socket bound to port ${_udpSocket!.port}');
    } catch (e) {
      print('Error setting up UDP: $e');
    }
  }

  /// Send mouse movement via UDP
  void sendMouseMove(double dx, double dy) {
    if (_udpSocket == null || _serverHost == null) return;

    final message = MouseMoveMessage(
      dx: dx,
      dy: dy,
      sequence: _udpSequence++,
    );

    final data = utf8.encode(message.toJsonString());
    _udpSocket!.send(
      data,
      InternetAddress(_serverHost!),
      _serverPort! + 1, // UDP port is WebSocket port + 1
    );
  }

  /// Send mouse click via WebSocket
  void sendMouseClick(String button, bool isDown) {
    if (_wsChannel == null) return;

    final message = MouseClickMessage(
      button: button,
      isDown: isDown,
    );
    _wsChannel!.sink.add(message.toJsonString());
  }

  /// Send scroll via WebSocket
  void sendScroll(double dx, double dy) {
    if (_wsChannel == null) return;

    final message = MouseScrollMessage(
      dx: dx,
      dy: dy,
    );
    _wsChannel!.sink.add(message.toJsonString());
  }

  /// Send key press via WebSocket
  void sendKeyPress(String key, List<String> modifiers, bool isDown) {
    if (_wsChannel == null) return;

    final message = KeyboardMessage(
      key: key,
      modifiers: modifiers,
      isDown: isDown,
    );
    _wsChannel!.sink.add(message.toJsonString());
  }

  /// Send text input via WebSocket
  void sendTextInput(String text) {
    if (_wsChannel == null) return;

    final message = TextInputMessage(text: text);
    _wsChannel!.sink.add(message.toJsonString());
  }

  /// Send media control via WebSocket
  void sendMediaControl(String action) {
    if (_wsChannel == null) return;

    final message = MediaMessage(action: action);
    _wsChannel!.sink.add(message.toJsonString());
  }

  Future<void> _saveToken(String deviceId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_$deviceId', token);
  }

  Future<String?> _getToken(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token_$deviceId');
  }

  Future<void> disconnect() async {
    await _wsChannel?.sink.close();
    _udpSocket?.close();
    _wsChannel = null;
    _udpSocket = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
