import 'base_message.dart';

/// Keyboard key press message
class KeyboardMessage extends BaseMessage {
  final String key;
  final List<String> modifiers; // 'cmd', 'ctrl', 'alt', 'shift'
  final bool isDown;

  KeyboardMessage({
    required this.key,
    this.modifiers = const [],
    required this.isDown,
    super.timestamp,
  }) : super(type: 'keyboard');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'key': key,
        'modifiers': modifiers,
        'isDown': isDown,
        'timestamp': timestamp,
      };

  factory KeyboardMessage.fromJson(Map<String, dynamic> json) {
    return KeyboardMessage(
      key: json['key'] as String,
      modifiers: (json['modifiers'] as List?)?.cast<String>() ?? [],
      isDown: json['isDown'] as bool,
      timestamp: json['timestamp'] as int?,
    );
  }
}

/// Text input message (for typing longer text)
class TextInputMessage extends BaseMessage {
  final String text;

  TextInputMessage({
    required this.text,
    super.timestamp,
  }) : super(type: 'text_input');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
        'timestamp': timestamp,
      };

  factory TextInputMessage.fromJson(Map<String, dynamic> json) {
    return TextInputMessage(
      text: json['text'] as String,
      timestamp: json['timestamp'] as int?,
    );
  }
}
