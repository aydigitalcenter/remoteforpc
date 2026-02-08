import 'base_message.dart';

/// Media control message
class MediaMessage extends BaseMessage {
  final String action; // 'play', 'pause', 'next', 'previous', 'volume_up', 'volume_down', 'mute'

  MediaMessage({
    required this.action,
    super.timestamp,
  }) : super(type: 'media');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'action': action,
        'timestamp': timestamp,
      };

  factory MediaMessage.fromJson(Map<String, dynamic> json) {
    return MediaMessage(
      action: json['action'] as String,
      timestamp: json['timestamp'] as int?,
    );
  }
}
