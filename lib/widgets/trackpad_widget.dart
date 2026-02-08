import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';

class TrackpadWidget extends StatefulWidget {
  final Function(double dx, double dy) onMove;
  final Function(String button) onTap;
  final Function(double dx, double dy) onScroll;

  const TrackpadWidget({
    super.key,
    required this.onMove,
    required this.onTap,
    required this.onScroll,
  });

  @override
  State<TrackpadWidget> createState() => _TrackpadWidgetState();
}

class _TrackpadWidgetState extends State<TrackpadWidget> {
  Offset? _lastPosition;
  int _pointerCount = 0;
  bool _isScrolling = false;
  Timer? _throttleTimer;
  static const _throttleDuration = Duration(milliseconds: 16); // ~60Hz

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[400]!, width: 2),
      ),
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: GestureDetector(
          onTap: () => _handleTap('left'),
          onLongPress: () => _handleTap('right'),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Trackpad',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1 finger: move • Tap: left click\n2 fingers: scroll • Long press: right click',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerCount++;
    _lastPosition = event.position;
    
    if (_pointerCount >= 2) {
      _isScrolling = true;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_lastPosition == null) return;

    final dx = event.position.dx - _lastPosition!.dx;
    final dy = event.position.dy - _lastPosition!.dy;

    if (_isScrolling && _pointerCount >= 2) {
      // Two-finger scroll
      _throttledCallback(() {
        widget.onScroll(dx * 0.5, dy * 0.5);
      });
    } else if (_pointerCount == 1) {
      // One-finger move
      _throttledCallback(() {
        widget.onMove(dx, dy);
      });
    }

    _lastPosition = event.position;
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointerCount--;
    if (_pointerCount <= 0) {
      _pointerCount = 0;
      _lastPosition = null;
      _isScrolling = false;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerCount--;
    if (_pointerCount <= 0) {
      _pointerCount = 0;
      _lastPosition = null;
      _isScrolling = false;
    }
  }

  void _handleTap(String button) {
    _vibrate();
    widget.onTap(button);
  }

  void _throttledCallback(VoidCallback callback) {
    if (_throttleTimer != null && _throttleTimer!.isActive) {
      return;
    }

    callback();
    _throttleTimer = Timer(_throttleDuration, () {});
  }

  Future<void> _vibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 10);
    }
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }
}
