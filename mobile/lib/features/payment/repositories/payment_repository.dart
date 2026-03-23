import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/payment_method.dart';

class PaymentRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _apiClient.dio.get('/api/payment-methods');
      final List<dynamic> data = response.data ?? [];
      return data
          .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['detail'] ?? 'Failed to fetch payment methods');
    }
  }

  Future<PaymentMethod> addPaymentMethod({
    required String cardholderName,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/payment-methods',
        data: {
          'cardholder_name': cardholderName,
          'card_number': cardNumber,
          'expiry_month': expiryMonth,
          'expiry_year': expiryYear,
          'cvc': cvc,
        },
      );
      return PaymentMethod.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['detail'] ?? 'Failed to add payment method');
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _apiClient.dio.delete('/api/payment-methods/$paymentMethodId');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['detail'] ?? 'Failed to delete payment method');
    }
  }

  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      await _apiClient.dio.patch(
        '/api/payment-methods/$paymentMethodId/set-default',
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ??
          'Failed to set default payment method');
    }
  }
}
