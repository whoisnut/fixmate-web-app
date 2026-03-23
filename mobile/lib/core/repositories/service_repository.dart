import '../network/api_client.dart';

class ServiceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _apiClient.getCategories();

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getServices({String? categoryId}) async {
    try {
      final response = await _apiClient.getServices(categoryId: categoryId);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch services');
      }
    } catch (e) {
      throw Exception('Error fetching services: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getService(String serviceId) async {
    try {
      final response = await _apiClient.getService(serviceId);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch service');
      }
    } catch (e) {
      throw Exception('Error fetching service: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> searchServices(String query) async {
    try {
      final allServices = await getServices();
      return allServices.where((service) {
        final name = (service['name'] as String?)?.toLowerCase() ?? '';
        final description =
            (service['description'] as String?)?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Error searching services: ${e.toString()}');
    }
  }
}
