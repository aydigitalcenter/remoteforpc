import 'base_message.dart';

/// Mouse movement message (sent via UDP)
class MouseMoveMessage extends BaseMessage {
  final double dx;
  final double dy;
  final int sequence;

  MouseMoveMessage({
    required this.dx,
    required this.dy,
    required this.sequence,
    super.timestamp,
  }) : super(type: 'mouse_move');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'dx': dx,
        'dy': dy,
        'seq': sequence,
        'timestamp': timestamp,
      };

  factory MouseMoveMessage.fromJson(Map<String, dynamic> json) {
    return MouseMoveMessage(
      dx: (json['dx'] as num).toDouble(),
      dy: (json['dy'] as num).toDouble(),
      sequence: json['seq'] as int,
      timestamp: json['timestamp'] as int?,
    );
  }
}

/// Mouse click message (sent via WebSocket)
class MouseClickMessage extends BaseMessage {
  final String button; // 'left', 'right', 'middle'
  final bool isDown;

  MouseClickMessage({
    required this.button,
    required this.isDown,
    super.timestamp,
  }) : super(type: 'mouse_click');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'button': button,
        'isDown': isDown,
        'timestamp': timestamp,
      };

  factory MouseClickMessage.fromJson(Map<String, dynamic> json) {
    return MouseClickMessage(
      button: json['button'] as String,
      isDown: json['isDown'] as bool,
      timestamp: json['timestamp'] as int?,
    );
  }
}

/// Mouse scroll message (sent via WebSocket)
class MouseScrollMessage extends BaseMessage {
  final double dx;
  final double dy;

  MouseScrollMessage({
    required this.dx,
    required this.dy,
    super.timestamp,
  }) : super(type: 'mouse_scroll');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'dx': dx,
        'dy': dy,
        'timestamp': timestamp,
      };

  factory MouseScrollMessage.fromJson(Map<String, dynamic> json) {
    return MouseScrollMessage(
      dx: (json['dx'] as num).toDouble(),
      dy: (json['dy'] as num).toDouble(),
      timestamp: json['timestamp'] as int?,
    );
  }
}
