/// Information about a discovered server
class ServerInfo {
  final String name;
  final String host;
  final int port;
  final String? version;

  ServerInfo({
    required this.name,
    required this.host,
    required this.port,
    this.version,
  });

  String get address => '$host:$port';

  @override
  String toString() => 'ServerInfo(name: $name, address: $address)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => name.hashCode ^ host.hashCode ^ port.hashCode;
}
