import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/repositories/review_repository.dart';
import 'package:mobile/models/review.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

// StateNotifier for managing review operations
class ReviewNotifier extends StateNotifier<AsyncValue<ReviewResponse?>> {
  final ReviewRepository _repository;

  ReviewNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      final review = await _repository.createReview(bookingId, rating, comment);
      state = AsyncValue.data(review);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// StateNotifierProvider for review management
final reviewProvider =
    StateNotifierProvider<ReviewNotifier, AsyncValue<ReviewResponse?>>(
  (ref) {
    final repo = ref.watch(reviewRepositoryProvider);
    return ReviewNotifier(repo);
  },
);

final createReviewProvider = FutureProvider.family<ReviewResponse,
    ({String bookingId, int rating, String? comment})>(
  (ref, params) async {
    final repo = ref.watch(reviewRepositoryProvider);
    return repo.createReview(params.bookingId, params.rating, params.comment);
  },
);

final getReviewProvider = FutureProvider.family<ReviewResponse, String>(
  (ref, bookingId) async {
    final repo = ref.watch(reviewRepositoryProvider);
    return repo.getReview(bookingId);
  },
);

final getTechnicianReviewsProvider = FutureProvider.family<
    ({int count, double averageRating, List<ReviewResponse> reviews}), String>(
  (ref, technicianId) async {
    final repo = ref.watch(reviewRepositoryProvider);
    return repo.getTechnicianReviews(technicianId);
  },
);
