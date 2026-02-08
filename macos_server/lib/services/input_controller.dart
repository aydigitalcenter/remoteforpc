import 'package:flutter/services.dart';

class InputController {
  static const MethodChannel _channel = MethodChannel('com.remoteforpc/input');

  /// Check if accessibility permission is granted
  Future<bool> checkAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAccessibility');
      return result ?? false;
    } catch (e) {
      print('Error checking accessibility permission: $e');
      return false;
    }
  }

  /// Request accessibility permission (opens System Preferences)
  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibility');
    } catch (e) {
      print('Error requesting accessibility permission: $e');
    }
  }

  /// Move mouse by relative delta
  Future<void> moveMouse(double dx, double dy) async {
    try {
      await _channel.invokeMethod('moveMouse', {
        'dx': dx,
        'dy': dy,
      });
    } catch (e) {
      print('Error moving mouse: $e');
    }
  }

  /// Perform mouse click
  Future<void> clickMouse(String button, bool isDown) async {
    try {
      await _channel.invokeMethod('clickMouse', {
        'button': button,
        'isDown': isDown,
      });
    } catch (e) {
      print('Error clicking mouse: $e');
    }
  }

  /// Scroll mouse wheel
  Future<void> scroll(double dx, double dy) async {
    try {
      await _channel.invokeMethod('scroll', {
        'dx': dx,
        'dy': dy,
      });
    } catch (e) {
      print('Error scrolling: $e');
    }
  }

  /// Press a key
  Future<void> pressKey(String key, List<String> modifiers, bool isDown) async {
    try {
      await _channel.invokeMethod('pressKey', {
        'key': key,
        'modifiers': modifiers,
        'isDown': isDown,
      });
    } catch (e) {
      print('Error pressing key: $e');
    }
  }

  /// Type text
  Future<void> typeText(String text) async {
    try {
      await _channel.invokeMethod('typeText', {
        'text': text,
      });
    } catch (e) {
      print('Error typing text: $e');
    }
  }

  /// Control media
  Future<void> controlMedia(String action) async {
    try {
      await _channel.invokeMethod('controlMedia', {
        'action': action,
      });
    } catch (e) {
      print('Error controlling media: $e');
    }
  }
}
