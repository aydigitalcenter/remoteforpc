import 'package:flutter/material.dart';
import 'package:remote_protocol/remote_protocol.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../services/connection_service.dart';
import 'controller_screen.dart';

class PairingScreen extends StatefulWidget {
  final ServerInfo server;

  const PairingScreen({super.key, required this.server});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _pinController = TextEditingController();
  final ConnectionService _connectionService = ConnectionService();
  bool _isConnecting = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 32),
            Text(
              'Connect to ${widget.server.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter the 6-digit PIN shown in the server menu',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, letterSpacing: 8),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '000000',
                counterText: '',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connect,
                child: _isConnecting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Connect', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect() async {
    final pin = _pinController.text.trim();
    
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit PIN')),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final deviceId = _getDeviceId();
      final deviceName = await _getDeviceName();

      final success = await _connectionService.connectWithPairing(
        host: widget.server.host,
        port: widget.server.port,
        pin: pin,
        deviceId: deviceId,
        deviceName: deviceName,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ControllerScreen(
              connectionService: _connectionService,
              server: widget.server,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_connectionService.errorMessage ?? 'Connection failed'),
          ),
        );
        setState(() => _isConnecting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isConnecting = false);
      }
    }
  }

  String _getDeviceId() {
    // In production, use device_info_plus to get actual device ID
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _getDeviceName() async {
    // In production, use device_info_plus to get actual device name
    if (Platform.isIOS) {
      return 'iPhone';
    } else if (Platform.isAndroid) {
      return 'Android Device';
    }
    return 'Mobile Device';
  }
}
