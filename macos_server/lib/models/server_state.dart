import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionState {
  idle,
  listening,
  connected,
  error,
}

class ConnectedDevice {
  final String deviceId;
  final String deviceName;
  final DateTime connectedAt;
  final WebSocketChannel channel;

  ConnectedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.connectedAt,
    required this.channel,
  });
}

class ServerState {
  final ConnectionState state;
  final List<ConnectedDevice> connectedDevices;
  final String? errorMessage;
  final bool hasAccessibilityPermission;

  ServerState({
    required this.state,
    this.connectedDevices = const [],
    this.errorMessage,
    this.hasAccessibilityPermission = false,
  });

  ServerState copyWith({
    ConnectionState? state,
    List<ConnectedDevice>? connectedDevices,
    String? errorMessage,
    bool? hasAccessibilityPermission,
  }) {
    return ServerState(
      state: state ?? this.state,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      errorMessage: errorMessage,
      hasAccessibilityPermission:
          hasAccessibilityPermission ?? this.hasAccessibilityPermission,
    );
  }

  int get clientCount => connectedDevices.length;
  bool get isConnected => connectedDevices.isNotEmpty;
}
