import '../network/api_client.dart';

class BookingRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required String address,
    required double lat,
    required double lng,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.createBooking({
        'service_id': serviceId,
        'address': address,
        'lat': lat,
        'lng': lng,
        'scheduled_at': scheduledAt.toIso8601String(),
        'notes': notes,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to create booking');
      }
    } catch (e) {
      throw Exception('Error creating booking: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getBookings({String? status}) async {
    try {
      final response = await _apiClient.getBookings(status: status);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        final list = data.map((item) => item as Map<String, dynamic>).toList();
        list.sort((a, b) {
          final aDate = DateTime.tryParse((a['created_at'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse((b['created_at'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        return list;
      } else {
        throw Exception('Failed to fetch bookings');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getBooking(String bookingId) async {
    try {
      final response = await _apiClient.getBooking(bookingId);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch booking');
      }
    } catch (e) {
      throw Exception('Error fetching booking: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.updateBooking(bookingId, updates);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update booking');
      }
    } catch (e) {
      throw Exception('Error updating booking: ${e.toString()}');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      final response = await _apiClient.cancelBooking(bookingId);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data?['detail'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      throw Exception('Error canceling booking: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getActiveBookings() async {
    return getBookings(status: 'active');
  }

  Future<List<Map<String, dynamic>>> getCompletedBookings() async {
    return getBookings(status: 'completed');
  }

  Future<List<Map<String, dynamic>>> getAvailableBookings() async {
    try {
      final response = await _apiClient.getAvailableBookings();

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch available bookings');
      }
    } catch (e) {
      throw Exception('Error fetching available bookings: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> acceptBooking(String bookingId) async {
    try {
      final response = await _apiClient.acceptBooking(bookingId);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to accept booking');
      }
    } catch (e) {
      throw Exception('Error accepting booking: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> startBooking(String bookingId) async {
    try {
      final response = await _apiClient.startBooking(bookingId);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to start booking');
      }
    } catch (e) {
      throw Exception('Error starting booking: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> completeBooking(String bookingId) async {
    try {
      final response = await _apiClient.completeBooking(bookingId);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
            response.data?['detail'] ?? 'Failed to complete booking');
      }
    } catch (e) {
      throw Exception('Error completing booking: ${e.toString()}');
    }
  }
}
