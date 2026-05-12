import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/models/message.dart';

class MessageRepository {
  final _apiClient = ApiClient();

  void _checkStatus(Response response) {
    if (response.statusCode != null && response.statusCode! >= 400) {
      final data = response.data;
      final message = (data is Map && data.containsKey('detail'))
          ? data['detail'].toString()
          : 'Request failed (${response.statusCode})';
      throw ApiException(message: message, statusCode: response.statusCode);
    }
  }

  Future<MessageResponse> sendMessage(String bookingId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/messages/$bookingId',
        data: {'content': content},
      );
      _checkStatus(response);
      return MessageResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<MessageResponse>> getBookingMessages(
    String bookingId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/messages/$bookingId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      _checkStatus(response);
      return (response.data as List)
          .map((m) => MessageResponse.fromJson(m))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ChatInfo>> getUserChats() async {
    try {
      final response = await _apiClient.dio.get('/api/messages/user/chats');
      _checkStatus(response);
      return (response.data as List).map((c) => ChatInfo.fromJson(c)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await _apiClient.dio.delete('/api/messages/$messageId');
      _checkStatus(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<MessageResponse> editMessage(String messageId, String content) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/messages/$messageId',
        data: {'content': content},
      );
      _checkStatus(response);
      return MessageResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
