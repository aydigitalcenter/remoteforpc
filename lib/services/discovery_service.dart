import 'package:multicast_dns/multicast_dns.dart';
import 'package:remote_protocol/remote_protocol.dart';

class DiscoveryService {
  final MDnsClient _mdnsClient = MDnsClient();
  bool _isDiscovering = false;

  /// Discover Remote Mouse servers on the local network
  Stream<ServerInfo> discoverServers({Duration timeout = const Duration(seconds: 5)}) async* {
    if (_isDiscovering) return;

    _isDiscovering = true;

    try {
      await _mdnsClient.start();

      await for (final PtrResourceRecord ptr in _mdnsClient
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer('_remotepc._tcp'),
          )
          .timeout(timeout)) {
        print('Found PTR record: ${ptr.domainName}');

        // Look up SRV record for port information
        await for (final SrvResourceRecord srv in _mdnsClient
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )
            .timeout(const Duration(seconds: 2))) {
          print('Found SRV record: ${srv.target}:${srv.port}');

          // Look up A record for IP address
          await for (final IPAddressResourceRecord ip in _mdnsClient
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )
              .timeout(const Duration(seconds: 2))) {
            print('Found IP: ${ip.address.address}');

            yield ServerInfo(
              name: ptr.domainName.replaceAll('._remotepc._tcp.local', ''),
              host: ip.address.address,
              port: srv.port,
            );
          }
        }
      }
    } catch (e) {
      print('Error discovering servers: $e');
    } finally {
      _mdnsClient.stop();
      _isDiscovering = false;
    }
  }

  /// Get list of servers (collects all from stream)
  Future<List<ServerInfo>> getServers({Duration timeout = const Duration(seconds: 5)}) async {
    final servers = <ServerInfo>[];
    
    await for (final server in discoverServers(timeout: timeout)) {
      if (!servers.contains(server)) {
        servers.add(server);
      }
    }

    return servers;
  }

  void dispose() {
    _mdnsClient.stop();
  }
}
