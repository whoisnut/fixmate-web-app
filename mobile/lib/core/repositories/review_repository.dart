import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/models/review.dart';

class ReviewRepository {
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

  Future<ReviewResponse> createReview(
      String bookingId, int rating, String? comment) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/reviews/$bookingId',
        data: {'rating': rating, 'comment': comment},
      );
      _checkStatus(response);
      return ReviewResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ReviewResponse> getReview(String bookingId) async {
    try {
      final response = await _apiClient.dio.get('/api/reviews/$bookingId');
      _checkStatus(response);
      return ReviewResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<({int count, double averageRating, List<ReviewResponse> reviews})>
      getTechnicianReviews(String technicianId) async {
    try {
      final response =
          await _apiClient.dio.get('/api/reviews/technician/$technicianId');
      _checkStatus(response);
      final data = response.data as Map<String, dynamic>;
      return (
        count: data['count'] as int,
        averageRating: (data['average_rating'] as num).toDouble(),
        reviews: (data['reviews'] as List)
            .map((r) => ReviewResponse.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ReviewResponse> updateReview(
      String reviewId, int rating, String? comment) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/reviews/$reviewId',
        data: {'rating': rating, 'comment': comment},
      );
      _checkStatus(response);
      return ReviewResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await _apiClient.dio.delete('/api/reviews/$reviewId');
      _checkStatus(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
