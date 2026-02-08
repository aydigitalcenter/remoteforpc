import 'base_message.dart';

/// Pairing request message
class PairRequestMessage extends BaseMessage {
  final String pin;
  final String deviceId;
  final String deviceName;

  PairRequestMessage({
    required this.pin,
    required this.deviceId,
    required this.deviceName,
    super.timestamp,
  }) : super(type: 'pair_request');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'pin': pin,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'timestamp': timestamp,
      };

  factory PairRequestMessage.fromJson(Map<String, dynamic> json) {
    return PairRequestMessage(
      pin: json['pin'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      timestamp: json['timestamp'] as int?,
    );
  }
}

/// Pairing response message
class PairResponseMessage extends BaseMessage {
  final bool success;
  final String? token;
  final String? errorMessage;

  PairResponseMessage({
    required this.success,
    this.token,
    this.errorMessage,
    super.timestamp,
  }) : super(type: 'pair_response');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'success': success,
        'token': token,
        'errorMessage': errorMessage,
        'timestamp': timestamp,
      };

  factory PairResponseMessage.fromJson(Map<String, dynamic> json) {
    return PairResponseMessage(
      success: json['success'] as bool,
      token: json['token'] as String?,
      errorMessage: json['errorMessage'] as String?,
      timestamp: json['timestamp'] as int?,
    );
  }
}

/// Authentication message (reconnection with stored token)
class AuthenticationMessage extends BaseMessage {
  final String token;
  final String deviceId;

  AuthenticationMessage({
    required this.token,
    required this.deviceId,
    super.timestamp,
  }) : super(type: 'authentication');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'token': token,
        'deviceId': deviceId,
        'timestamp': timestamp,
      };

  factory AuthenticationMessage.fromJson(Map<String, dynamic> json) {
    return AuthenticationMessage(
      token: json['token'] as String,
      deviceId: json['deviceId'] as String,
      timestamp: json['timestamp'] as int?,
    );
  }
}
