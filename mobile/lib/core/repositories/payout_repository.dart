import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/models/payout.dart';

class PayoutRepository {
  final _apiClient = ApiClient();

  Future<PayoutResponse> createPayoutRequest({
    required double amount,
    required String method,
    required String paymentAccount,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/payouts',
        data: {
          'amount': amount,
          'method': method,
          'payment_account': paymentAccount,
        },
      );
      return PayoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<PayoutResponse>> getMyPayouts() async {
    try {
      final response = await _apiClient.dio.get('/api/payouts/my-requests');
      return (response.data as List)
          .map((p) => PayoutResponse.fromJson(p))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PayoutResponse> getPayout(String payoutId) async {
    try {
      final response = await _apiClient.dio.get('/api/payouts/$payoutId');
      return PayoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
