import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  WebSocketService._internal();

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  bool get isConnected => _channel != null;

  Future<void> connect({required String userId, required String token}) async {
    if (_channel != null) await disconnect();

    final baseWs = AppConstants.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$baseWs/api/ws/$userId?token=$token');

    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _eventController.add(data);
        } catch (_) {}
      },
      onError: (error) => _eventController.addError(error),
      onDone: () => _channel = null,
    );
  }

  void send(String type, Map<String, dynamic> data) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _eventController.close();
    _channel?.sink.close();
  }
}
