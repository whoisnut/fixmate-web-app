import '../network/api_client.dart';

class PaymentRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> createPayment({
    required String bookingId,
    required double amount,
    required String method,
  }) async {
    try {
      final response = await _apiClient.createPayment({
        'booking_id': bookingId,
        'amount': amount,
        'method': method,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error creating payment: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getPayment(String bookingId) async {
    try {
      final response = await _apiClient.getPayment(bookingId);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch payment');
      }
    } catch (e) {
      throw Exception('Error fetching payment: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updatePaymentStatus(
    String paymentId,
    String status, {
    String? transactionId,
  }) async {
    try {
      final response = await _apiClient.updatePaymentStatus(
        paymentId,
        status,
        transactionId: transactionId,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update payment');
      }
    } catch (e) {
      throw Exception('Error updating payment: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getMyPayments() async {
    try {
      final response = await _apiClient.getMyPayments();

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch payments');
      }
    } catch (e) {
      throw Exception('Error fetching payments: ${e.toString()}');
    }
  }
}
