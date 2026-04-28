import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/repositories/review_repository.dart';
import 'package:mobile/models/review.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

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
