import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/models/message.dart';

class MessageRepository {
  final _apiClient = ApiClient();

  Future<MessageResponse> sendMessage(String bookingId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/messages/$bookingId',
        data: {'content': content},
      );
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
      return (response.data as List).map((c) => ChatInfo.fromJson(c)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiClient.dio.delete('/api/messages/$messageId');
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
      return MessageResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
