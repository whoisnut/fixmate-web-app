import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/models/review.dart';

class ReviewRepository {
  final _apiClient = ApiClient();

  Future<ReviewResponse> createReview(
      String bookingId, int rating, String? comment) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/reviews/$bookingId',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
      return ReviewResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ReviewResponse> getReview(String bookingId) async {
    try {
      final response = await _apiClient.dio.get('/api/reviews/$bookingId');
      return ReviewResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<({int count, double averageRating, List<ReviewResponse> reviews})>
      getTechnicianReviews(String technicianId) async {
    try {
      final response =
          await _apiClient.dio.get('/api/reviews/technician/$technicianId');
      final data = response.data;
      return (
        count: data['count'] as int,
        averageRating: (data['average_rating'] as num).toDouble(),
        reviews: (data['reviews'] as List)
            .map((r) => ReviewResponse.fromJson(r))
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
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
      return ReviewResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _apiClient.dio.delete('/api/reviews/$reviewId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
