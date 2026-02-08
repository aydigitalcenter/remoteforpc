import 'dart:convert';

/// Base class for all protocol messages
abstract class BaseMessage {
  final String type;
  final int timestamp;

  BaseMessage({
    required this.type,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  /// Convert message to JSON
  Map<String, dynamic> toJson();

  /// Convert to JSON string for network transmission
  String toJsonString() => jsonEncode(toJson());

  /// Parse message from JSON
  static BaseMessage? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;

    // Factory method to create specific message types
    // Will be implemented by each message type
    return null;
  }
}
