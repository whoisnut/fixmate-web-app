import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/service_repository.dart';

final serviceRepositoryProvider = Provider((ref) => ServiceRepository());

final categoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getCategories();
});

final servicesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, categoryId) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getServices(categoryId: categoryId);
});

final serviceDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, serviceId) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getService(serviceId);
});

final searchServicesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, query) async {
  final repository = ref.watch(serviceRepositoryProvider);
  if (query.isEmpty) {
    return [];
  }
  return repository.searchServices(query);
});
