import 'package:flutter/services.dart';

class BonjourService {
  static const MethodChannel _channel = MethodChannel('com.remoteforpc/bonjour');

  /// Start advertising the service
  Future<void> startAdvertising({
    required String serviceName,
    required int port,
  }) async {
    try {
      await _channel.invokeMethod('startAdvertising', {
        'serviceName': serviceName,
        'port': port,
      });
      print('Bonjour service started: $serviceName on port $port');
    } catch (e) {
      print('Error starting Bonjour service: $e');
    }
  }

  /// Stop advertising the service
  Future<void> stopAdvertising() async {
    try {
      await _channel.invokeMethod('stopAdvertising');
      print('Bonjour service stopped');
    } catch (e) {
      print('Error stopping Bonjour service: $e');
    }
  }
}
