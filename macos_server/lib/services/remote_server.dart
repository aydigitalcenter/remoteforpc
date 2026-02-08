import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:remote_protocol/remote_protocol.dart';

import 'websocket_server.dart';
import 'udp_server.dart';
import 'input_controller.dart';
import 'bonjour_service.dart';
import '../models/server_state.dart';

class RemoteServer extends ChangeNotifier {
  static const int websocketPort = 8080;
  static const int udpPort = 8081;

  WebSocketServer? _wsServer;
  UdpServer? _udpServer;
  final InputController _inputController = InputController();
  final BonjourService _bonjourService = BonjourService();

  ServerState _state = ServerState(state: ConnectionState.idle);
  String _pin = '';
  final Map<String, String> _pairedDevices = {}; // deviceId -> token
  final Map<WebSocketChannel, String> _authenticatedClients = {}; // channel -> deviceId

  ServerState get state => _state;
  String get pin => _pin;

  RemoteServer() {
    _initialize();
  }

  Future<void> _initialize() async {
    _generatePin();
    await _loadPairedDevices();
    await _checkPermissions();
  }

  void _generatePin() {
    _pin = (100000 + DateTime.now().millisecond * 8999 ~/ 999).toString().substring(0, 6);
    print('Generated PIN: $_pin');
  }

  Future<void> _loadPairedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devices = prefs.getStringList('paired_devices') ?? [];
      for (final device in devices) {
        final parts = device.split(':');
        if (parts.length == 2) {
          _pairedDevices[parts[0]] = parts[1];
        }
      }
      print('Loaded ${_pairedDevices.length} paired devices');
    } catch (e) {
      print('Error loading paired devices: $e');
    }
  }

  Future<void> _savePairedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devices = _pairedDevices.entries
          .map((e) => '${e.key}:${e.value}')
          .toList();
      await prefs.setStringList('paired_devices', devices);
    } catch (e) {
      print('Error saving paired devices: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _inputController.checkAccessibilityPermission();
    _updateState(_state.copyWith(hasAccessibilityPermission: hasPermission));
    
    if (!hasPermission) {
      print('Accessibility permission not granted');
    }
  }

  Future<void> requestAccessibilityPermission() async {
    await _inputController.requestAccessibilityPermission();
    // Check again after a delay
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  Future<void> start() async {
    try {
      // Start WebSocket server
      _wsServer = WebSocketServer(
        port: websocketPort,
        onMessageReceived: _handleMessage,
        onClientConnected: _handleClientConnected,
        onClientDisconnected: _handleClientDisconnected,
      );
      await _wsServer!.start();

      // Start UDP server
      _udpServer = UdpServer(
        port: udpPort,
        onMouseMove: _handleMouseMove,
      );
      await _udpServer!.start();

      // Start Bonjour advertising
      await _bonjourService.startAdvertising(
        serviceName: 'Remote Mouse',
        port: websocketPort,
      );

      _updateState(_state.copyWith(state: ConnectionState.listening));
      print('Server started successfully');
    } catch (e) {
      print('Error starting server: $e');
      _updateState(_state.copyWith(
        state: ConnectionState.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> stop() async {
    try {
      await _wsServer?.stop();
      await _udpServer?.stop();
      await _bonjourService.stopAdvertising();
      
      _authenticatedClients.clear();
      _updateState(ServerState(state: ConnectionState.idle));
      print('Server stopped');
    } catch (e) {
      print('Error stopping server: $e');
    }
  }

  void _handleClientConnected(WebSocketChannel channel) {
    // Client connected, waiting for authentication
    print('Client connected, waiting for authentication');
  }

  void _handleClientDisconnected(WebSocketChannel channel) {
    final deviceId = _authenticatedClients.remove(channel);
    if (deviceId != null) {
      final devices = List<ConnectedDevice>.from(_state.connectedDevices);
      devices.removeWhere((d) => d.deviceId == deviceId);
      _updateState(_state.copyWith(connectedDevices: devices));
      print('Device $deviceId disconnected');
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'pair_request':
        _handlePairRequest(data);
        break;
      case 'authentication':
        _handleAuthentication(data);
        break;
      case 'mouse_click':
        _handleMouseClick(data);
        break;
      case 'mouse_scroll':
        _handleMouseScroll(data);
        break;
      case 'keyboard':
        _handleKeyboard(data);
        break;
      case 'text_input':
        _handleTextInput(data);
        break;
      case 'media':
        _handleMedia(data);
        break;
    }
  }

  void _handlePairRequest(Map<String, dynamic> data) {
    final message = PairRequestMessage.fromJson(data);
    
    if (message.pin == _pin) {
      // Generate token
      final token = const Uuid().v4();
      _pairedDevices[message.deviceId] = token;
      _savePairedDevices();

      // Send success response
      final response = PairResponseMessage(
        success: true,
        token: token,
      );
      _wsServer?.broadcast(jsonEncode(response.toJson()));
      
      print('Device ${message.deviceName} paired successfully');
    } else {
      // Send failure response
      final response = PairResponseMessage(
        success: false,
        errorMessage: 'Invalid PIN',
      );
      _wsServer?.broadcast(jsonEncode(response.toJson()));
      
      print('Pairing failed: Invalid PIN');
    }
  }

  void _handleAuthentication(Map<String, dynamic> data) {
    // Find the client channel - for simplicity, we'll authenticate all current clients
    // In production, you'd track which channel sent this message
    final message = AuthenticationMessage.fromJson(data);
    
    if (_pairedDevices[message.deviceId] == message.token) {
      // Authentication successful
      // Add to authenticated clients list
      print('Device ${message.deviceId} authenticated');
      
      // For now, we'll update state to show connected
      _updateState(_state.copyWith(state: ConnectionState.connected));
    } else {
      print('Authentication failed for device ${message.deviceId}');
    }
  }

  void _handleMouseMove(MouseMoveMessage message) {
    if (!_state.hasAccessibilityPermission) return;
    _inputController.moveMouse(message.dx, message.dy);
  }

  void _handleMouseClick(Map<String, dynamic> data) {
    if (!_state.hasAccessibilityPermission) return;
    final message = MouseClickMessage.fromJson(data);
    _inputController.clickMouse(message.button, message.isDown);
  }

  void _handleMouseScroll(Map<String, dynamic> data) {
    if (!_state.hasAccessibilityPermission) return;
    final message = MouseScrollMessage.fromJson(data);
    _inputController.scroll(message.dx, message.dy);
  }

  void _handleKeyboard(Map<String, dynamic> data) {
    if (!_state.hasAccessibilityPermission) return;
    final message = KeyboardMessage.fromJson(data);
    _inputController.pressKey(message.key, message.modifiers, message.isDown);
  }

  void _handleTextInput(Map<String, dynamic> data) {
    if (!_state.hasAccessibilityPermission) return;
    final message = TextInputMessage.fromJson(data);
    _inputController.typeText(message.text);
  }

  void _handleMedia(Map<String, dynamic> data) {
    final message = MediaMessage.fromJson(data);
    _inputController.controlMedia(message.action);
  }

  void _updateState(ServerState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
