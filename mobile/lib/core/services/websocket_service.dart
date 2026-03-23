import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  late WebSocketChannel? _channel;
  late StreamController<Map<String, dynamic>> _eventController;

  WebSocketService._internal() {
    _eventController = StreamController<Map<String, dynamic>>.broadcast();
  }

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect({
    required String userId,
    required String token,
  }) async {
    try {
      if (_channel != null) {
        await disconnect();
      }

      final wsUrl = AppConstants.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      final uri = Uri.parse('$wsUrl/api/ws/$userId?token=$token');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> data = _parseMessage(message);
            _eventController.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _eventController.addError(error);
        },
        onDone: () {
          print('WebSocket connection closed');
          _channel = null;
        },
      );

      print('WebSocket connected for user: $userId');
    } catch (e) {
      print('Error connecting WebSocket: $e');
      rethrow;
    }
  }

  void sendMessage(String type, Map<String, dynamic> data) {
    if (_channel == null) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(_encodeMessage(message));
  }

  Future<void> disconnect() async {
    try {
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  // Helper methods
  Map<String, dynamic> _parseMessage(dynamic message) {
    if (message is String) {
      // Assume JSON string
      try {
        return Map<String, dynamic>.from(
          _jsonDecode(message),
        );
      } catch (e) {
        return {'type': 'unknown', 'message': message};
      }
    }
    return {};
  }

  String _encodeMessage(Map<String, dynamic> message) {
    return _jsonEncode(message);
  }

  // JSON helper methods (using dart:convert equivalent)
  dynamic _jsonDecode(String source) {
    // Using a simple JSON parser or external package
    // For now, returning raw string
    return source;
  }

  String _jsonEncode(dynamic value) {
    // Using a simple JSON encoder or external package
    // For now, returning raw string
    return value.toString();
  }

  void dispose() {
    _eventController.close();
    _channel?.sink.close();
  }
}
