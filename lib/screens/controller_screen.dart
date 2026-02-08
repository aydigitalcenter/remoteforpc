import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:remote_protocol/remote_protocol.dart';
import '../services/connection_service.dart';
import '../widgets/trackpad_widget.dart';

class ControllerScreen extends StatefulWidget {
  final ConnectionService connectionService;
  final ServerInfo server;

  const ControllerScreen({
    super.key,
    required this.connectionService,
    required this.server,
  });

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  bool _showKeyboard = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _disconnect,
        ),
        actions: [
          IconButton(
            icon: Icon(_showKeyboard ? Icons.keyboard_hide : Icons.keyboard),
            onPressed: () {
              setState(() => _showKeyboard = !_showKeyboard);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Media controls
          _buildMediaControls(),
          
          // Trackpad area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TrackpadWidget(
                onMove: (dx, dy) {
                  widget.connectionService.sendMouseMove(dx, dy);
                },
                onTap: (button) {
                  widget.connectionService.sendMouseClick(button, true);
                  Future.delayed(const Duration(milliseconds: 50), () {
                    widget.connectionService.sendMouseClick(button, false);
                  });
                },
                onScroll: (dx, dy) {
                  widget.connectionService.sendScroll(dx, dy);
                },
              ),
            ),
          ),
          
          // Keyboard (if shown)
          if (_showKeyboard) _buildKeyboard(),
        ],
      ),
    );
  }

  Widget _buildMediaControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () {
              widget.connectionService.sendMediaControl('previous');
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            iconSize: 36,
            onPressed: () {
              widget.connectionService.sendMediaControl('play');
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () {
              widget.connectionService.sendMediaControl('next');
            },
          ),
          IconButton(
            icon: const Icon(Icons.volume_down),
            onPressed: () {
              widget.connectionService.sendMediaControl('volume_down');
            },
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {
              widget.connectionService.sendMediaControl('volume_up');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simple text input field
          TextField(
            decoration: const InputDecoration(
              hintText: 'Type here...',
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: (text) {
              widget.connectionService.sendTextInput(text);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect?'),
        content: const Text('Are you sure you want to disconnect?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (shouldDisconnect == true) {
      await widget.connectionService.disconnect();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
